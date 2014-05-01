function [tforms, mean_error] = tikhonov_old(matches_fixed, matches_moving, varargin)
%TIKHONOV_OLD Solves a set of transformations for each tile in the match pair.
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

[matches_fixed, matches_moving, params] = parse_inputs(matches_fixed, matches_moving, varargin{:});

tic
% Calculate some stuff
num_matches = size(matches_fixed, 1);
base_sec = min(min(matches_fixed.section(:)), min(matches_moving.section(:)));
num_secs = max(max(matches_fixed.section(:)), max(matches_moving.section(:))) - base_sec + 1;

% Pre-allocate matrices
A = zeros(num_matches, num_secs * params.num_tiles * 3);
gamma = zeros(num_matches, num_secs * params.num_tiles * 3);

% Calculate the column indices for each point
col_fixed = (matches_fixed.section - base_sec) * params.num_tiles * 3 + (matches_fixed.tile - 1) * 3 + 1;
col_moving = (matches_moving.section - base_sec) * params.num_tiles * 3 + (matches_moving.tile - 1) * 3 + 1;

% Pad the points
fixed_pts_padded = [matches_fixed.global_points ones(num_matches, 1)];
moving_pts_padded = [matches_moving.global_points ones(num_matches, 1)];

% The b vector is pretty trivial, just the moving points padded with ones
b = moving_pts_padded;

% Fill out matrices with matched points
for i = 1:num_matches
    % Fill in row for rigidity matrix (A)
    A(i, col_moving:col_moving+2) = moving_pts_padded(i, :);
    
    % Fill in row for alignment matrix (gamma)
    gamma(i, col_moving(i):col_moving(i) + 2) = moving_pts_padded(i, :);
    gamma(i, col_fixed(i):col_fixed(i) + 2) = -fixed_pts_padded(i, :);
end

% Solve
x_hat = (params.lambda .^ 2 * (A' * A) + gamma' * gamma) \ (params.lambda .^ 2 * A' * b);
%x_hat = x_hat(:, 1:2); % drop the last column (~[0 0 1]')

% Sanity check
assert(~any(any(isnan(x_hat))))

% Splice out solution into tforms
tforms = cell(num_secs, params.num_tiles);
for s = 1:num_secs
    for t = 1:params.num_tiles
        i = (s - 1) * params.num_tiles * 3 + (t - 1) * 3 + 1; % row in x_hat
        tforms{s, t} = affine2d([x_hat(i:i+2, 1:2) [0 0 1]']);
    end
end

% Apply transforms to points
registered_ptsA = zeros(num_matches, 2);
registered_ptsB = zeros(num_matches, 2);
for i = 1:num_matches
    registered_ptsA(i, :) = tforms{matches_fixed.section(i) - base_sec + 1, matches_fixed.tile(i)}.transformPointsForward(matches_fixed.global_points(i, :));
    registered_ptsB(i, :) = tforms{matches_moving.section(i) - base_sec + 1, matches_moving.tile(i)}.transformPointsForward(matches_moving.global_points(i, :));
end

% Calculate registration error
distances = calculate_match_distances(registered_ptsA, registered_ptsB);
mean_error = sum(distances) / num_matches;

fprintf('Calculated registration transforms. Registration error: %.3fpx/match. [%.2fs]\n', mean_error, toc)

end

function [matches_fixed, matches_moving, params] = parse_inputs(matches_fixed, matches_moving, varargin)
% Create inputParser instance
p = inputParser;

% Required parameters
p.addRequired('matches_fixed');
p.addRequired('matches_moving');

% Other parameters
p.addParameter('num_tiles', 16)
p.addParameter('lambda', 0.005);

% Debugging and visualization
p.addParameter('verbosity', 0);
p.addParameter('show_region_stats', true);

% Validate and parse input
p.parse(matches_fixed, matches_moving, varargin{:});
matches_fixed = p.Results.matches_fixed;
matches_moving = p.Results.matches_moving;
params = rmfield(p.Results, {'matches_fixed', 'matches_moving'});
end