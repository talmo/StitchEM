% Loads a set of matches, solves their alignment transform and renders.

%% Load matches
% Choose match set
match_sets = dir('match_sets/sec*.mat');
current_set = 6;

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

%% Find best lambda
% Calculate slopes (approximate derivative)
dErr = diff(mean_errors) ./ diff(lambdas);

% Find local minima
minima = find([false; (dErr(2:end-1) < dErr(3:end)) & (dErr(2:end-1) < dErr(1:end-2)); false]);

% Plot rigidity curve and its derivative
figure, subplot(1, 2, 1)
semilogx(lambdas, mean_errors, 'bx-', lambdas(minima), mean_errors(minima), 'ro')
title('Rigidity curve')
xlabel('lambda')
ylabel('Mean registration error (px)')

subplot(1, 2, 2)
loglog(lambdas(1:end-1), dErr, 'cx-', lambdas(minima), dErr(minima), 'ro')
title('Approximate derivative')
xlabel('lambda')
ylabel('\deltaError/\deltalambda')

%% Solve transforms
% The lambda to use for the rigidity parameter
%lambda = lambdas(minima);

lambda = 0.0189281615401724; % point of inflection
%lambda = 0.000574164245593572; % low end of plateau
%lambda = 0.423161379345088; % high end of plateau

% Solve for the transforms
secs = align_section_stack(secs, matchesA, matchesB, 'lambda', lambda);

%% Render

%render_path = sprintf('renders/sec%d-%d', secs{1}.num, secs{end}.num);
render_path = 'renders/sec22-149_matches_2014-04-09_high_lambda';

render_stack(secs, 'render_scale', 1.0, 'path', render_path)