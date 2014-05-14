function plot_section(sec, alignment, PatchSpec)
%PLOT_SECTION Plots the bounding boxes of the tiles of the section structure.
% Usage:
%   plot_section(sec)
%   plot_section(sec, alignment)
%   plot_section(sec, alignment, PatchSpec)
%
% See also: sec_bb, plot_regions, draw_polys, draw_poly

if nargin < 2
    bounding_boxes = sec_bb(sec);
else
    bounding_boxes = sec_bb(sec, alignment);
end
if nargin < 3
    PatchSpec = '0.5';
end

% Draw each bounding box with the same PatchSpec
draw_polys(bounding_boxes, PatchSpec, 'KeepPlotColor', true)

% Cycle colors if we used the next one
if ~instr(PatchSpec, ['[' get_color_names() ']'], 'r')
    cycle_plot_colors()
end
    
% Adjust the figure
grid on
ax2int()
if nargin < 2
    title(sprintf('Section %d', sec.num))
else
    title(sprintf('Section %d | Alignment: %s', sec.num, alignment))
end

end

