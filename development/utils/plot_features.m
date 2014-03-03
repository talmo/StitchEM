function plot_features(features, scale)
%PLOT_FEATURES Plots point features.

if nargin < 2
    scale = 1.0;
end

if istable(features)
    features = features.global_points;
end

% Scale the points
features = transformPointsForward(scale_tform(scale), features);

% Plot the points
plot(features(:,1), features(:,2), 'g+')
end

