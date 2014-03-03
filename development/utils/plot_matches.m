function plot_matches(matched_pts1, matched_pts2, scale)
%PLOT_MATCHES Plots the pair of matching points.

if nargin < 3
    scale = 1.0;
end

% Scale the points
matched_pts1 = transformPointsForward(scale_tform(scale), matched_pts1);
matched_pts2 = transformPointsForward(scale_tform(scale), matched_pts2);

% Plot the points
plot(matched_pts1(:,1), matched_pts1(:,2), 'ro')
plot(matched_pts2(:,1), matched_pts2(:,2), 'g+')

% Plot the lines between the points
lineX = [matched_pts1(:,1)'; matched_pts2(:,1)'];
numPts = numel(lineX);
lineX = [lineX; NaN(1,numPts/2)];
lineY = [matched_pts1(:,2)'; matched_pts2(:,2)'];
lineY = [lineY; NaN(1,numPts/2)];
plot(lineX(:), lineY(:), 'y-');
end

