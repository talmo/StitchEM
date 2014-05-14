function varargout = draw_poly(P, varargin)
%DRAW_POLY Plots a polygon from a set of points.
%
% Usage:
%   draw_poly(P)
%   draw_poly(Px, Py)
%   draw_poly(Px, Py, patch_spec)
%
% Args:
%   P is a Mx2 or 2xM matrix containing a set of points which define the
%       polygon by their convex hull.
%   Px, Py are Mx1 or 1xM vectors of the x and y coordinates of P.
%   patch_spec is '?0.75' by default. This is a string that specifies the
%       short name for the color of the face of the patch, followed by the
%       alpha transparency value between 0 and 1.0. Setting the color to
%       '?' will set the color to the next color on the current axes.
%
% Returns:
%   V (Nx2) or Vx, Vy (Nx1) when there are one or more outputs. V contains
%       the vertices of the convex hull of the points P. These are the
%       vertices of the polygon displayed.
%
% See also: draw_polys, plot_regions

% Process inputs
[Vx, Vy, Px, Py, params] = parse_inputs(P, varargin{:});

% Save previous hold state
hold_state = get_hold_state;
hold all

% Detect face color of the patch
if isempty(params.PatchFaceColor)
    FaceColor = 'none';
elseif strcmp(params.PatchFaceColor, '?')
    FaceColor = get_next_plot_color;
else
    FaceColor = params.PatchFaceColor;
end

% Draw patch!
patch('XData', Vx, 'YData', Vy, 'FaceColor', FaceColor, 'FaceAlpha', params.PatchFaceAlpha, params.PatchParams)

% Plot the original points if linespec is non-empty
if ~isempty(params.P_LineSpec)
    plot(Px, Py, params.P_LineSpec)
end

% Plot the convex hull if linespec is non-empty
if ~isempty(params.V_LineSpec)
    plot(Vx, Vy, params.V_LineSpec)
end

% Restore previous hold state
hold(hold_state);
if nargout == 2
    varargout = {Vx, Vy};
elseif nargout >= 1
    varargout = {[Vx Vy]};
end
end

function [Vx, Vy, Px, Py, params] = parse_inputs(P, varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Points
p.addRequired('P_', @(x) validateattributes(x, {'numeric'}, {'2d', 'nonempty'}));
p.addOptional('Py', @(x) validateattr(x, {'numeric'}, {'vector', 'nonempty'}));

% Patch specifications
patch_spec_regex = '';
p.addOptional('PatchSpec', '?0.5', @(x) ischar(x));

% Validate and parse input
p.parse(P, varargin{:});

% Post-process points
if isvector(p.Results.P_) && length(p.Results.P_) == length(p.Results.Py)
    % Ensure Px and Py are column vectors
    Px = p.Results.P_(:);
    Py = p.Results.Py(:);
elseif any(size(p.Results.P_) == 2)
    P = p.Results.P_;
    
    % Ensure P is a vertical matrix
    if size(P, 2) ~= 2 % P does not have 2 columns iff P has 2 rows
        P = P';
    end
    
    Px = P(:, 1);
    Py = P(:, 2);
else
    error('The points must be specified as a Mx2 or 2xM matrix, or by two Mx1 or 1xM vectors.')
end

% Compute convex hull of the set of points
K = convhull(double(Px), double(Py));
Vx = Px(K);
Vy = Py(K);

% Parse any remaining parameters
other_params = p.Unmatched;

% Create inputParser instance
p2 = inputParser;
p2.KeepUnmatched = true;

% Patch specifications


% Line specifications
p2.addParameter('P_LineSpec', '');
p2.addParameter('V_LineSpec', 'k*-');

% Validate and parse input
p2.parse(other_params);
params = p2.Results;
params.PatchParams = p2.Unmatched;

% Parse the PatchSpec string
color_table = ColorSpec;
short_colors = strjoin(color_table.short_names', '');
named_tokens = regexpi(params.PatchSpec, ['(?<color>(?:next|[?])?|[' short_colors ']?)(?<alpha>[01]?(?:[.]\d+)?)'], 'names');
face_color = strrep(named_tokens.color, 'next', '?');
face_alpha = str2double(named_tokens.alpha);

% Defaults
if isnan(face_alpha); face_alpha = 0.75; end;

% Save to params
params.PatchFaceColor = face_color;
params.PatchFaceAlpha = face_alpha;

end