function plot_xy_features(sec, tile)
%PLOT_XY_FEATURES Plots a section and its XY features.
% Usage:
%   plot_xy_features(sec)
%   plot_xy_features(sec, tile)
%
% See also: plot_z_features

% Draw section
figure
plot_section(sec, sec.features.xy.alignment, 'r0.1')
hold on

if nargin > 1
    features = sec.features.xy.tiles{tile};
else
    features = merge_features(sec.features.xy.tiles);
end

plot_features(features)

end

