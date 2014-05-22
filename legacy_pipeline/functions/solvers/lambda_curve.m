function varargout = lambda_curve(matchesA, matchesB, varargin)
%LAMBDA_CURVE Plot the curve of lambda vs error for a pair of matchsets.

% Process input
[lambdas, params, unmatched_params] = parse_inputs(varargin{:});

if params.verbosity > 0
    fprintf('== Generating rigidity curve (lambdas = %g -> %g | n = %d).\n', min(lambdas), max(lambdas), length(lambdas))
end
lambda_curve_time = tic;

% Turn off warnings about bad scaling
pctRunOnAll warning('off', 'MATLAB:nearlySingularMatrix')
warning('off', 'MATLAB:nearlySingularMatrix')

% Calculate transforms at different lambdas
mean_errors = zeros(length(lambdas), 1);
parfor i = 1:length(lambdas);
    [~, mean_errors(i)] = tikhonov_sparse(matchesA, matchesB, 'lambda', lambdas(i), 'verbosity', 0, unmatched_params);
end

% Turn warnings about bad scaling back on
pctRunOnAll warning('on', 'MATLAB:nearlySingularMatrix')
warning('on', 'MATLAB:nearlySingularMatrix')

if params.verbosity > 0
    [min_error, min_idx] = min(mean_errors);
    fprintf('Done. Minimum error = %.2fpx @ lambda = %g. [%.2fs]\n', min_error, lambdas(min_idx), toc(lambda_curve_time))
end

% Plot results
figure
if params.log_plot
    semilogx(lambdas, mean_errors, 'x-')
else
    plot(lambdas, mean_errors, 'x-')
end
title('Rigidity curve')
xlabel('lambda')
ylabel('Mean registration error (px)')

% Output
if nargout > 0
    varargout = {lambdas, mean_errors};
end

end

function [lambdas, params, unmatched] = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Parameters
p.addOptional('lambdas', logspace(-3, 3, 50));
p.addParameter('log_plot', true);
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
lambdas = reshape(p.Results.lambdas, length(p.Results.lambdas), 1); % column vector
params = rmfield(p.Results, 'lambdas');
unmatched = p.Unmatched;

end