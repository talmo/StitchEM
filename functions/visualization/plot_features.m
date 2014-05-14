function plot_features(features, scale, marker)
%PLOT_FEATURES Plots point features.
%
% Usage:
%   plot_features(features)
%   plot_features(features, scale)
%   plot_features(features, scale, marker)
%
% Args:
%   features is an Mx2 numeric array of points, or a table with the columns
%       'global_points' or 'local_points'.
%   scale specifies a factor to scale the points by. Defaults to 1.0.
%   marker specifies the point marker to use to plot the features. Defaults
%       to 'g+'.
%
% See also: plot_matches, plot_section_matches, detect_surf_features.

if nargin < 2
    scale = 1.0;
end
if nargin < 3
    marker = 'g+';
end

if istable(features)
    if instr('global_points', features.Properties.VariableNames)
        features = features.global_points;
    elseif instr('local_points', features.Properties.VariableNames)
        features = features.local_points;
    else
        error('Features table has no global_points and local_points columns.')
    end
end


% Scale the points
if scale ~= 1.0
    features = features * scale;
end
hold on

% Plot the points
plot(features(:,1), features(:,2), marker)

integer_axes(1/scale);
hold off
end

