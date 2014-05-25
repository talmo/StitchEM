function varargout = draw_poly(points, varargin)
%DRAW_POLY Plots a polygon from a set of points.
%
% Usage:
%   draw_poly(P)
%   draw_poly(Px, Py)
%   draw_poly(..., PatchSpec)
%   V = draw_poly(...)
%   [Vx, Vy] = draw_poly(...)
%
% Args:
%   P is a Mx2 or 2xM matrix containing a set of points which define the
%       polygon by their convex hull.
%   Px, Py are Mx1 or 1xM vectors of the x and y coordinates of P.
%   PatchSpec is a string that specifies how to display the polygon. This
%       may be any character from ColorSpec and a double specifying the
%       opacity of the patch. If the color is omitted, the next plot color
%       is used. Defaults to '0.5'.
%
% Parameters:
%   'PointsLineSpec' is the LineSpec of the points. Leave empty to
%       disable plotting the points. Defaults to ''.
%   'VertexLineSpec' is the LineSpec of the vertices. Leave empty to
%       disable plotting the vertices. Defaults to '.'.
%   'Axis' calls axis() with its contents as parameters. Defaults to 
%       {'ij', 'equal'}, which adjusts the axes to match the display style
%       of an image. See axis() for more.
%   'KeepPlotColor' is a scalar logical that specifies whether to keep the
%       plot color fixed. If this is true, repeated calls to this function
%       will draw polygons with the same color. Defaults to false.
%
% Returns:
%   V (Nx2) or Vx, Vy (Nx1) when there are one or more outputs. V contains
%       the vertices of the convex hull of the points P. These are the
%       vertices of the polygon displayed.
%
% See also: draw_polys, plot_regions, get_next_plot_color, ColorSpec, axis

% Process inputs
[Vx, Vy, Px, Py, params] = parse_inputs(points, varargin{:});

% Use next plot color if none specified by user
if isempty(params.PatchColor)
    params.PatchColor = get_next_plot_color();
    
    % Cycle to next plot color
    if ~params.KeepPlotColor
        cycle_plot_colors()
    end
end

% Draw patch!
patch('XData', Vx, 'YData', Vy, 'FaceColor', params.PatchColor, 'FaceAlpha', params.PatchAlpha, 'EdgeColor', params.PatchColor)

% Save previous hold state
hold_state = get_hold_state();
hold all

% Plot the original points if LineSpec is non-empty
if ~isempty(params.PointsLineSpec)
    ColorParam = {};
    if params.PointsUsePatchColor; ColorParam = {'Color', params.PatchColor}; end
    plot(Px, Py, params.PointsLineSpec, ColorParam{:})
    cycle_plot_colors(-1)
end

% Plot the vertices if the LineSpec is non-empty
if ~isempty(params.VertexLineSpec)
    ColorParam = {};
    if params.VertexUsePatchColor; ColorParam = {'Color', params.PatchColor}; end
    plot(Vx, Vy, params.VertexLineSpec, ColorParam{:})
    cycle_plot_colors(-1)
end

% Adjust axis settings
if ~isempty(params.Axis)
    axis(params.Axis{:})
end

% Restore previous hold state
hold(hold_state);

% Output
if nargout > 1
    varargout = {Vx, Vy};
elseif nargout == 1
    varargout = {[Vx Vy]};
end
end

function [Vx, Vy, Px, Py, params] = parse_inputs(points, varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Points
if isempty(varargin) || ischar(varargin{1})
    [Px, Py] = validatepoints(points);
else
    [Px, Py] = validatepoints(points, varargin{1});
    varargin(1) = [];
end

% Compute convex hull of the set of points to get polygon vertices
K = convhull(double(Px), double(Py), 'simplify', true);
Vx = Px(K);
Vy = Py(K);

% Create inputParser instance
p = inputParser;

% Patch specifications
ColorPattern = ['[' get_color_names() ']'];
AlphaPattern = '([01]?[.]\d+|[01])';
p.addOptional('PatchSpec', '0.5', @(x) instr(x, ColorPattern, 'r') || instr(x, AlphaPattern, 'r'));

% Point and vertex specifications
p.addParameter('PointsLineSpec', '');
p.addParameter('VertexLineSpec', '.');

% Adjust axes properties
p.addParameter('Axis', {'ij', 'equal'});

% Keep plot color
p.addParameter('KeepPlotColor', false);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

% Post-process patch specification
matches = regexp(params.PatchSpec, {ColorPattern, AlphaPattern}, 'once', 'ignorecase', 'match');
params.PatchColor = matches{1};
params.PatchAlpha = str2double(matches{2});
if isnan(params.PatchAlpha)
    params.PatchAlpha = 0.5;
elseif params.PatchAlpha > 1.0
    params.PatchAlpha = 1.0;
elseif params.PatchAlpha < 0
    params.PatchAlpha = 0;
end

% Use the same color as the patch to plot the points unless user specifies
% a color in the LineSpec
params.PointsUsePatchColor = ~instr(params.PointsLineSpec, ColorPattern, 'r');
params.VertexUsePatchColor = ~instr(params.VertexLineSpec, ColorPattern, 'r');
end