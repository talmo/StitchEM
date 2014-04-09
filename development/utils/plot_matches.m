function plot_matches(matched_pts1, matched_pts2, scale, alt_colors)
%PLOT_MATCHES Plots the pair of matching points.
% Usage:
%   PLOT_MATCHES(matched_pts1, matched_pts2)
%   PLOT_MATCHES(matched_pts1, matched_pts2, scale)
%   PLOT_MATCHES(matched_pts1, matched_pts2, scale, alt_colors)
%
% Notes:
%   - scale = 1.0 (default)
%   - alt_colors = false (default), if true displays matches using
%   alternative color scheme
if nargin < 3
    scale = 1.0;
end
if nargin < 4
    alt_colors = false;
end

if alt_colors
    pts_marker1 = 'mo';
    pts_marker2 = 'c+';
    line_marker = 'b-';
else
    pts_marker1 = 'ro';
    pts_marker2 = 'g+';
    line_marker = 'y-';
end

% Handle tables
if istable(matched_pts1)
    matched_pts1 = matched_pts1.global_points;
end
if istable(matched_pts2)
    matched_pts2 = matched_pts2.global_points;
end

% Scale the points
matched_pts1 = transformPointsForward(scale_tform(scale), matched_pts1);
matched_pts2 = transformPointsForward(scale_tform(scale), matched_pts2);

hold on
% Plot the points
plot(matched_pts1(:,1), matched_pts1(:,2), pts_marker1)
plot(matched_pts2(:,1), matched_pts2(:,2), pts_marker2)

% Plot the lines between the points
lineX = [matched_pts1(:,1)'; matched_pts2(:,1)'];
numPts = numel(lineX);
lineX = [lineX; NaN(1,numPts/2)];
lineY = [matched_pts1(:,2)'; matched_pts2(:,2)'];
lineY = [lineY; NaN(1,numPts/2)];
plot(lineX(:), lineY(:), line_marker);
hold off
end

