function plot_displacements(displacements)
%PLOT_DISPLACEMENTS Plots displacements with their geometric median.

% Find the geometric median of the displacements
M = geomedian(displacements);

% Plot
scatter(displacements(:,1), displacements(:,2), 'ko')
hold on, grid on
plot(M(1), M(2), 'r*')
title('Displacements')
hold off

end

