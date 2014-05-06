function varargout = tform_warnings(state)
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
    warning(warning_state, w{1})
    
    % Parallel
    if matlabpool('size')
        pctRunOnAll(['warning(''' warning_state ''', ''' w{1} ''')'])
    end
end

if nargout > 0
    varargout = {warning_state};
end
end

