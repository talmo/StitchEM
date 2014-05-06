function cur_state = tform_warnings(state)
%TFORM_WARNINGS Turns warnings about bad transformations on or off.

% Warnings
warnings = {'MATLAB:nearlySingularMatrix'};

% Keep track of current state
persistent warning_state;
if isempty(warning_state)
    s = warning('query', warnings{1});
    warning_state = s.state;
end

% If not explicitly specified, toggle state
if nargin < 1
    if strcmpi(warning_state, 'on')
        warning_state = 'off';
    else
        warning_state = 'on';
    end
else
    validatestring(state, {'on', 'off'})
    warning_state = state;
end

% Change the state of each warning
for w = warnings(:)'
    warning(warning_state, 'MATLAB:nearlySingularMatrix')
    
    % Parallel
    if matlabpool('size')
        pctRunOnAll sprintf(warning('off', 'MATLAB:nearlySingularMatrix')
    end
end

cur_state = warning_state;

end

