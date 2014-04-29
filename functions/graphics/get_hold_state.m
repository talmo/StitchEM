function state = get_hold_state(ax)
%GET_HOLD_STATE Returns the state of hold as a string: 'on', 'off' or 'all'.
% Detects the 'all' state, unlike ishold(). Also does not create a new
% figure if one is not already open.
%
% Args:
%   ax optionally specifies the handle to the axes object to query. This
%   defaults to the current axes on the current figure.

if nargin < 1
    fig = get(0, 'CurrentFigure');
    ax = get(fig, 'CurrentAxes');
else
    ax = ax(1);
    fig = ancestor(ax, 'figure');
end

% The axes does not exist
if isempty(ax)
    % The default value of 'NextPlot' for a new axes is 'replace', so the
    % hold state will be 'off'
    state = 'off';
    return
end

% Compare the figure and axes properties to determine state
if strcmp(get(ax, 'NextPlot'), 'add') && strcmp(get(fig, 'NextPlot'), 'add')
    if getappdata(ax, 'PlotHoldStyle')
        state = 'all';
    else
        state = 'on';
    end
else
    state = 'off';
end

end

