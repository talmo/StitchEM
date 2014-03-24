function plot_features(features, scale, marker)
%PLOT_FEATURES Plots point features.

if nargin < 2
    scale = 1.0;
end
if nargin < 3
    marker = 'g+';
end

if istable(features)
    features = features.global_points;
end

if scale ~= 1.0
    % Scale the points
    features = transformPointsForward(scale_tform(scale), features);
end

% Plot the points
plot(features(:,1), features(:,2), marker)

integer_axes(1/scale);
end

