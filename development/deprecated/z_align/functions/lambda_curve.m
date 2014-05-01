function [varargout] = lambda_curve(matchesA, matchesB, varargin)
%LAMBDA_CURVE Plot the curve of lambda vs error for a pair of matchsets.

% Process input
[params, unmatched_params] = parse_inputs(varargin{:});


if params.exp_scale
    lambdas = (10 .^ (params.low:params.step:params.high))';
else
    lambdas = (params.low:params.step:params.high)';
end

% Turn off warnings about bad scaling
pctRunOnAll warning('off', 'MATLAB:nearlySingularMatrix')

fprintf('Generating rigidity curve with %d different lambdas.\n', length(lambdas))

% Calculate transforms at different lambdas
mean_errors = zeros(length(lambdas), 1);
parfor i = 1:length(lambdas);
    [~, mean_errors(i)] = tikhonov(matchesA, matchesB, 'lambda', lambdas(i), 'verbosity', 0, unmatched_params);
end

% Turn warnings about bad scaling back on
pctRunOnAll warning('on', 'MATLAB:nearlySingularMatrix')

% Plot results
figure
if params.exp_scale
    semilogx(lambdas, mean_errors, 'x-')
else
    plot(lambdas, mean_errors, 'x-')
end
title('Rigidity curve')
xlabel('lambda')
ylabel('Mean registration error (px)')
if nargout > 0
    varargout = {lambdas, mean_errors};
end

end

function [params, unmatched] = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Data points
p.addParameter('low', -3);
p.addParameter('step', 0.1);
p.addParameter('high', 3);
p.addParameter('exp_scale', true);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;

end