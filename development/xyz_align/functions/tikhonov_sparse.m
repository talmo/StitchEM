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

tic
% Figure out some constants
sec_nums = unique([unique(matchesA.section); unique(matchesB.section)]);
num_secs = length(sec_nums);
num_matches = size(matchesA, 1);
tile_nums = arrayfun(@(sec) unique([matchesA.tile(matchesA.section == sec); matchesB.tile(matchesB.section == sec)]), sec_nums, 'UniformOutput', false);
num_sec_tiles = cellfun(@(x) length(x), tile_nums);
num_tiles = sum(num_sec_tiles);

% Use indices instead of the actual tile/section number
secIdxA = arrayfun(@(s) find(sec_nums == s), matchesA.section);
secIdxB = arrayfun(@(s) find(sec_nums == s), matchesB.section);
tileIdxA = cellfun(@(sec_tile) find(tile_nums{sec_tile(1)} == sec_tile(2)), num2cell([secIdxA matchesA.tile], 2));
tileIdxB = cellfun(@(sec_tile) find(tile_nums{sec_tile(1)} == sec_tile(2)), num2cell([secIdxB matchesB.tile], 2));

% Pre-allocate matrices
A = spalloc(num_matches, num_tiles * 3, num_matches * 3);
gamma = spalloc(num_matches, num_tiles * 3, num_matches * 6);

% Calculate the column indices for each point
colA = arrayfun(@(s) sum(num_sec_tiles(1:s-1)), secIdxA) * 3 + (tileIdxA - 1) * 3 + 1;
colB = arrayfun(@(s) sum(num_sec_tiles(1:s-1)), secIdxB) * 3 + (tileIdxB - 1) * 3 + 1;

% Pad the points
ptsA_padded = [matchesA.global_points ones(num_matches, 1)];
ptsB_padded = [matchesB.global_points ones(num_matches, 1)];

% The b vector is pretty trivial, just the moving points padded with ones
b = double(ptsB_padded);

% Fill out matrices with matched points
for i = 1:num_matches
    % Fill in row for rigidity matrix (A)
    A(i, colB(i):colB(i) + 2) = ptsB_padded(i, :);
    
    % Fill in row for alignment matrix (gamma)
    gamma(i, colB(i):colB(i) + 2) = ptsB_padded(i, :);
    gamma(i, colA(i):colA(i) + 2) = -ptsA_padded(i, :);
end

% Solve
%A = sparse(A);
%gamma = sparse(gamma);
%b = sparse(b);
x_hat = full((params.lambda .^ 2 * (A' * A) + gamma' * gamma) \ (params.lambda .^ 2 * A' * b));

% Sanity checking
if any(any(isnan(x_hat)))
    error('Failed to calculate transforms with lambda = %s', num2str(params.lambda))
end

% Splice out solution into tforms
tforms = cell(num_secs, max([max(matchesA.tile); max(matchesB.tile)]));
for s = 1:num_secs
    for t = 1:length(tile_nums{s})
        i = sum(num_sec_tiles(1:s-1)) * 3 + (t - 1) * 3 + 1; % row in x_hat
        t2 = tile_nums{s}(t);
        tforms{s, t2} = affine2d([x_hat(i:i+2, 1:2) [0 0 1]']);
    end
end

% Transform matching points to estimate error
registered_ptsA = zeros(size(matchesA, 1), 2);
registered_ptsB = zeros(size(matchesB, 1), 2);
for s = 1:num_secs
    for t = 1:num_sec_tiles(s)
        idxA = secIdxA == s & tileIdxA == t;
        global_pointsA = matchesA.global_points(idxA, :);
        if ~isempty(global_pointsA)
            registered_ptsA(idxA, 1:2) = tforms{s, tile_nums{s}(t)}.transformPointsForward(global_pointsA);
        end
        
        idxB = secIdxB == s & tileIdxB == t;
        global_pointsB = matchesB.global_points(idxB, :);
        if ~isempty(global_pointsB)
            registered_ptsB(idxB, 1:2) = tforms{s, tile_nums{s}(t)}.transformPointsForward(global_pointsB);
        end
    end
end

% Calculate registration error
distances = calculate_match_distances(registered_ptsA, registered_ptsB);

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