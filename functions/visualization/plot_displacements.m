function plot_displacements(displacements)
%PLOT_DISPLACEMENTS Plots match displacements with their geometric median.
%
% Usage:
%   plot_displacements(displacements)
%
% Args:
%   displacements is a Mx2 matrix of displacements.
%
%
% Example:
%   displacements = matches.B.global_points - matches.A.global_points;
%   plot_displacements(displacements)

% Find the geometric median of the displacements
M = geomedian(displacements);

% Plot
scatter(displacements(:,1), displacements(:,2), 'ko')
axis equal
hold on, grid on
plot(M(1), M(2), 'r*')
title('Displacements')
hold off

end

