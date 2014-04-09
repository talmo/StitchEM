% Loads a set of matches, solves their alignment transform and renders.

%% Load matches
% Choose match set
match_sets = dir('match_sets/sec*.mat');
current_set = 2;

% Load to workspace
match_set = match_sets(current_set).name;
tic; load(sprintf('match_sets/%s', match_set))
fprintf('Match set %s: Loaded %d matches from cache [%.2fs].\n', match_set, height(matchesA), toc)

%% Calculate rigidity curve
% To figure out the optimal lambda, plot a range of them and choose a value
% in the middle plateau region.
%
% This parameter controls the balance between minimizing the displacement
% between the matching points and keeping the tiles fixed.
%
% The "rigidity" is a constraint introduced to prevent calculating a set of
% transforms that minimize the displacement by scaling the tiles to an
% apparent singularity. This behavior is reproducible by setting the lambda
% to a very small value.
%
% Warning: This may take a while to compute with larger numbers of matches.

% Plot a range of lambdas
[lambdas, mean_errors] = lambda_curve(matchesA, matchesB, logspace(-3, 3, 30));

% Narrow down to a local minimum to find the ideal parameter
%lambda_curve(matchesA, matchesB, linspace(0.125 - 0.05, 0.125 + 0.05, 50), 'log_plot', false)

%% Solve transforms
% The lambda to use for the rigidity parameter
lambda = 0.015;

% Solve for the transforms
secs = align_section_stack(secs, matchesA, matchesB, 'lambda', lambda);

%% Render
%profile clear
%profile on
render_path = sprintf('renders/sec%d-%d', secs{1}.num, secs{end}.num);

render_stack(secs, 'render_scale', 1.0, 'path', render_path)
%profile viewer