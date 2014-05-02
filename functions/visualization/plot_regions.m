function plot_regions(regions, scale)
%PLOT_REGIONS Plots regions specified as polygons.

if nargin < 2
    scale = 1.0;
end

% Draw the regions
draw_polys(regions);

% Adjust the figure
grid on
title('Regions')
ax2int(scale)

end

