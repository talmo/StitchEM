function plot_z_features(sec, tile)
%PLOT_Z_FEATURES Plots a section and its Z features.
% Usage:
%   plot_z_features(sec)
%   plot_z_features(sec, tile)
%
% See also: plot_xy_features

% Draw section
figure
plot_section(sec, sec.features.z.alignment, 'r0.1')
hold on

if nargin > 1
    features = sec.features.z.tiles{tile};
else
    features = merge_features(sec.features.z.tiles);
end

plot_features(features)

end

