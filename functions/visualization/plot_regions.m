function plot_regions(regions, scale, use_different_colors)
%PLOT_REGIONS Plots regions specified as polygons.
% Usage:
%   plot_regions(regions)
%   plot_regions(regions, scale)
%   plot_regions(regions, scale, use_different_colors)
%
% Set use_different_colors to true to plot each region in a different color.
% 
% See also: plot_section, draw_polys

if nargin < 2
    scale = 1.0;
end
if nargin < 3
    use_different_colors = false;
end

% Draw the regions
draw_polys(regions, 'KeepPlotColor', ~use_different_colors)

% Cycle colors if we used the next one
if ~use_different_colors
    cycle_plot_colors()
end

% Adjust the figure
grid on
ax2int(scale)

end

