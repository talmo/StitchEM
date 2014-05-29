function [tforms, mean_error, varargout] = tikhonov_sparse(matchesA, matchesB, varargin)
%TIKHONOV_SPARSE Solves a set of transformations for each tile in the match pair.
% Usage:
%   [tforms, mean_error] = TIKHONOV_SPARSE(matchesA, matchesB)
%   [tforms, mean_error, stats] = TIKHONOV_SPARSE(...)
%   TIKHONOV_SPARSE(..., 'Name', 'Value')
%
% Name-value pairs:
%   'lambda', 0.005
%   'adjust_error', true
%   'verbosity', 1
%
% See TIKHONOV for more info.

[matchesA, matchesB, params] = parse_inputs(matchesA, matchesB, varargin{:});

tic;

% Calculate some constants for indexing
sec_nums = unique([unique(matchesA.section); unique(matchesB.section)]);
num_secs = length(sec_nums);
tile_nums = arrayfun(@(s) unique([unique(matchesA.tile(matchesA.section == s)); unique(matchesB.tile(matchesB.section == s))]), sec_nums, 'UniformOutput', false);
num_tiles = cellfun(@(t) length(t), tile_nums);
cum_num_tiles = cumsum(num_tiles) - num_tiles(1);

total_tiles = cum_num_tiles(end) + num_tiles(1);
num_matches = height(matchesA);

% Build index arrays
Ja = zeros(height(matchesA), 1);
Jb = zeros(height(matchesB), 1);
for s = 1:num_secs
    tile_idx = zeros(1, length(tile_nums{s}));
    for t = min(tile_nums{s}):max(tile_nums{s})
        idx = find(tile_nums{s} == t, 1);
        if ~isempty(idx)
            tile_idx(t) = idx;
        end
    end
    
    Ia = matchesA.section == sec_nums(s);
    Ja(Ia) = cum_num_tiles(s) * 3 + (tile_idx(matchesA.tile(Ia)) - 1) * 3 + 1;
    
    Ib = matchesB.section == sec_nums(s);
    Jb(Ib) = cum_num_tiles(s) * 3 + (tile_idx(matchesB.tile(Ib)) - 1) * 3 + 1;
end

Ia = repmat((1:num_matches)', 3, 1);
Ib = repmat((1:num_matches)', 3, 1);

Ja = [Ja; Ja + 1; Ja + 2];
Jb = [Jb; Jb + 1; Jb + 2];

% Points
Sa = -[double(matchesA.global_points(:)); ones(num_matches, 1)];
Sb = [double(matchesB.global_points(:)); ones(num_matches, 1)];

% Sparse matrix sizes
m = num_matches;
n = total_tiles * 3;
nnzA = num_matches * 3;
nnzGamma = nnzA * 2;

% Create sparse matrices
A = sparse(Ib, Jb, Sb, m, n, nnzA);
gamma = sparse([Ib; Ia], [Jb; Ja], [Sb; Sa], m, n, nnzGamma);
b = reshape(Sb, num_matches, 3);

% Solve
x_hat = full((params.lambda .^ 2 * (A' * A) + gamma' * gamma) \ (params.lambda .^ 2 * A' * b));
x_hat = [x_hat(:, 1:2) repmat([0 0 1]', size(x_hat, 1) / 3, 1)]; % Fix last column

% Sanity checking
if any(any(isnan(x_hat)))
    error('Failed to calculate transforms with lambda = %s', num2str(params.lambda))
end

% Splice out solution into tforms
Ts = cellfun(@(T) {affine2d(T)}, mat2cell(x_hat, repmat(3, 1, total_tiles), 3));
tforms = cell(num_secs, max(num_tiles));
for s = 1:num_secs
    tforms(s, 1:num_tiles(s)) = Ts(cum_num_tiles(s) + 1: cum_num_tiles(s) + num_tiles(s));
end

% Transform matching points to estimate error
ptsA_sp = sparse(Ia, Ja, -Sa, m, n, nnzA);
ptsA = ptsA_sp * x_hat; ptsB = A * x_hat;
ptsA = ptsA(:, 1:2);    ptsB = ptsB(:, 1:2);

% Calculate registration error
distances = calculate_match_distances(ptsA, ptsB);

% Adjust error for scale
if params.adjust_error
    % Matches should be at the same scale
    assert(all(matchesA.scale == matchesB.scale))
    
    % Adjust the distances between the registered matches by their scale
    distances = distances .* matchesA.scale;
end

mean_error = mean(distances);

if params.verbosity > 0
    fprintf('Calculated registration transforms. Registration error: %.3fpx/match. [%.2fs]\n', mean_error, toc)
end

% Additional output parameters
if nargout > 2
    % Technically, we're minimizing this residual:
    stats.residual = norm(A * x_hat - b) .^ 2 + norm(gamma * x_hat) .^ 2;
    stats.rigidity_res = norm(A * x_hat - b) .^ 2;
    stats.alignment_res = norm(gamma * x_hat) .^ 2;
    
    % Break distances down by scale
    scales = unique(matchesA.scale);
    for s = 1:length(scales)
        stats.scales(s).scale = scales{s};
        stats.scales(s).distances = distances(matchesA.scale == scales{s});
    end
    varargout = {stats};
end

end

function [matchesA, matchesB, params] = parse_inputs(matchesA, matchesB, varargin)
% Create inputParser instance
p = inputParser;

% Required parameters
p.addRequired('matchesA');
p.addRequired('matchesB');

% Lambda
p.addParameter('lambda', 0.005);

% Error reporting
p.addParameter('adjust_error', true); % adjust reported error for scale

% Debugging and visualization
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(matchesA, matchesB, varargin{:});
matchesA = p.Results.matchesA;
matchesB = p.Results.matchesB;
params = rmfield(p.Results, {'matchesA', 'matchesB'});
end