function plot_section(sec, alignment, PatchSpec)
%PLOT_SECTION Plots the bounding boxes of the tiles of the section structure.
% Usage:
%   plot_section(sec)
%   plot_section(sec, alignment)
%   plot_section(sec, alignment, PatchSpec)
%
% See also: plot_tile, plot_regions, sec_bb, draw_polys

if nargin < 2
    alignments = fieldnames(sec.alignments);
    alignment = alignments{end};
end
if nargin < 3
    PatchSpec = '0.1';
end

% Get bounding boxes
bounding_boxes = sec_bb(sec, alignment);

% Draw each bounding box with the same PatchSpec
draw_polys(bounding_boxes, PatchSpec, 'KeepPlotColor', true)

% Cycle colors if we didn't specify one explicitly
if ~instr(PatchSpec, ['[' get_color_names() ']'], 'r')
    cycle_plot_colors()
end
    
% Adjust the figure
grid on
axis equal
ax2int()
append_title(strrep(sprintf('\\bfSection\\rm: %s | \\bfAlignment\\rm: %s', sec.name, alignment), '_', '\_'))
end

