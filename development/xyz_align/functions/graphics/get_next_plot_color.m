function varargout = get_next_plot_color(color_format, reset_color)
%GET_NEXT_PLOT_COLOR Returns the next color that the plot function would use.
% Set the color_format to 'rgb', 'long_name', or 'short_name' to return the
% color in a different format.
% Defaults to long_name if there are 0 output arguments, otherwise RGB.
% If reset_color is set to true, repeated calls to this function will
% return the same color(default = false).

if nargin < 1
    if nargout == 0
        color_format = 'long_name';
    else
        color_format = 'rgb';
    end
else
    color_format = validatestring(color_format, {'rgb', 'long_name', 'short_name'});
end

if nargin < 2
    reset_color = false;
end

hold_state = get_hold_state;
hold all

h = plot(NaN, NaN); % Plot a dummy point and save the handle to its object
rgb_color = get(h, 'Color'); % Get the color from the object properties
if reset_color
    h = plot(NaN(2, size(get(gca, 'ColorOrder'), 1) - 1)); % Reset to the previous color by plotting more dummy points
end
delete(h); % Delete the dummy points' object

hold(hold_state); % Reset to previous hold state

switch color_format
    case 'rgb'
        color = rgb_color;
    case 'long_name'
        color = rgb2name(rgb_color, true);
    case 'short_name'
        color = rgb2name(rgb_color, false);
end

% Output
if nargout == 0
    if ~ischar(color) || isempty(color)
        color = mat2str(rgb_color);
    end
    fprintf('Next color: %s\n', color)
else
    varargout = {color};
end

end

