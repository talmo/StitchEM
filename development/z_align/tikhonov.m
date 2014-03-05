function [tforms, mean_error] = tikhonov(matchesA, matchesB, varargin)
%TIKHONOV Solves a set of transformations for each tile in the match pair.
% Registers fixed onto moving
%
% This algorithm is also known as ridge regression, although the Tikhonov
% matrix utilized is generally identity, whereas we use this form to solve
% for our linear transformations.
%
% We minimize the cost function:
% cost = ||A * x - b|| ^ 2 + ||gamma * x|| ^ 2
% A contains one set of points for one seam per block row
% b contains the same set of points but as a 2 column block vector
% gamma contains two sets of points (correspondencies) for one seam per
%   block row (Tikhonov matrix)
%
% Reference: Tikhonov, A. N. (1963). [Solution of incorrectly formulated problems and the regularization method].
% Doklady Akademii Nauk SSSR 151: 501504. Translated in Soviet Mathematics 4: 10351038.

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
A = zeros(num_matches, num_tiles * 3);
gamma = zeros(num_matches, num_tiles * 3);

% Calculate the column indices for each point
colA = arrayfun(@(s) sum(num_sec_tiles(1:s-1)), secIdxA) * 3 + (tileIdxA - 1) * 3 + 1;
colB = arrayfun(@(s) sum(num_sec_tiles(1:s-1)), secIdxB) * 3 + (tileIdxB - 1) * 3 + 1;

% Pad the points
ptsA_padded = [matchesA.global_points ones(num_matches, 1)];
ptsB_padded = [matchesB.global_points ones(num_matches, 1)];

% The b vector is pretty trivial, just the moving points padded with ones
b = ptsB_padded;

% Fill out matrices with matched points
for i = 1:num_matches
    % Fill in row for rigidity matrix (A)
    A(i, colB(i):colB(i) + 2) = ptsB_padded(i, :);
    
    % Fill in row for alignment matrix (gamma)
    gamma(i, colB(i):colB(i) + 2) = ptsB_padded(i, :);
    gamma(i, colA(i):colA(i) + 2) = -ptsA_padded(i, :);
end

% Solve
x_hat = (params.lambda .^ 2 * (A' * A) + gamma' * gamma) \ (params.lambda .^ 2 * A' * b);
x_hat = x_hat(:, 1:2); % drop the last column (~[0 0 1]')

% Sanity checking
assert(~any(any(isnan(x_hat))))

% Splice out solution into tforms
tforms = cell(num_secs, max([max(matchesA.tile); max(matchesB.tile)]));
for s = 1:num_secs
    for t = 1:length(tile_nums{s})
        i = sum(num_sec_tiles(1:s-1)) * 3 + (t - 1) * 3 + 1; % row in x_hat
        t2 = tile_nums{s}(t);
        tforms{s, t2} = affine2d([x_hat(i:i+2, 1:2) [0 0 1]']);
    end
end

% Apply transforms to moving points
registered_ptsA = zeros(num_matches, 2);
registered_ptsB = zeros(num_matches, 2);
for i = 1:num_matches
    registered_ptsA(i, :) = tforms{secIdxA(i), matchesA.tile(i)}.transformPointsForward(matchesA.global_points(i, :));
    registered_ptsB(i, :) = tforms{secIdxB(i), matchesB.tile(i)}.transformPointsForward(matchesB.global_points(i, :));
end

% Calculate registration error
distances = calculate_match_distances(registered_ptsA, registered_ptsB);
mean_error = sum(distances) / num_matches;

fprintf('Calculated registration transforms. Registration error: %.3fpx/match. [%.2fs]\n', mean_error, toc)

end

function [matchesA, matchesB, params] = parse_inputs(matchesA, matchesB, varargin)
% Create inputParser instance
p = inputParser;

% Required parameters
p.addRequired('matchesA');
p.addRequired('matchesB');

% Other parameters
%p.addParameter('num_tiles', 16)
p.addParameter('lambda', 0.005);

% Debugging and visualization
p.addParameter('verbosity', 0);
p.addParameter('show_region_stats', true);

% Validate and parse input
p.parse(matchesA, matchesB, varargin{:});
matchesA = p.Results.matchesA;
matchesB = p.Results.matchesB;
params = rmfield(p.Results, {'matchesA', 'matchesB'});
end