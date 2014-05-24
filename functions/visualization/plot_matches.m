function plot_matches(ptsA, ptsB, scale, alt_colors)
%PLOT_MATCHES Plots the pair of matching points.
% Usage:
%   plot_matches(ptsA, ptsB)
%   plot_matches(ptsA, ptsB, scale)
%   plot_matches(ptsA, ptsB, scale, alt_colors)
%
% Notes:
%   - scale = 1.0 (default)
%   - alt_colors = false (default), if true displays matches using
%   alternative color scheme

% Handle match structs
if isstruct(ptsA)
    if isfield(ptsA, 'match_sets')
        matches = merge_match_sets(ptsA);
        ptsA = matches.A;
        ptsB = matches.B;
    elseif isfield(ptsA, 'A') && isfield(ptsA, 'B')
        ptsB = ptsA.B;
        ptsA = ptsA.A;
    end
end

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
if istable(ptsA)
    ptsA = ptsA.global_points;
end
if istable(ptsB)
    ptsB = ptsB.global_points;
end


% Scale the points
ptsA = transformPointsForward(make_tform('scale', scale), ptsA);
ptsB = transformPointsForward(make_tform('scale', scale), ptsB);

hold on
% Plot the points
plot(ptsA(:,1), ptsA(:,2), pts_marker1)
plot(ptsB(:,1), ptsB(:,2), pts_marker2)

% Plot the lines between the points
lineX = [ptsA(:,1)'; ptsB(:,1)'];
numPts = numel(lineX);
lineX = [lineX; NaN(1,numPts/2)];
lineY = [ptsA(:,2)'; ptsB(:,2)'];
lineY = [lineY; NaN(1,numPts/2)];
plot(lineX(:), lineY(:), line_marker);
hold off
end

