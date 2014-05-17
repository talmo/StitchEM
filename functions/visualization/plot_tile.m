function plot_tile(sec, tile, alignment, PatchSpec)
%PLOT_TILE Plots the bounding box of the specified tile.
% Usage:
%   plot_tile(sec)
%   plot_tile(sec, tile)
%   plot_tile(sec, tile, alignment)
%   plot_tile(sec, tile, alignment, PatchSpec)
%
% See also: plot_section, plot_regions, draw_poly

if nargin < 2
    tile = 1;
end
if nargin < 3
    alignments = fieldnames(sec.alignments);
    alignment = alignments{end};
end
if nargin < 4
    PatchSpec = '0.1';
end

% Get bounding boxes
bounding_boxes = sec_bb(sec, alignment);

% Draw bounding box of specified tile
draw_poly(bounding_boxes{tile}, PatchSpec)

% Cycle colors if we used the next one
if ~instr(PatchSpec, ['[' get_color_names() ']'], 'r')
    cycle_plot_colors()
end

% Adjust the figure
grid on
axis equal
ax2int()
append_title(sprintf('Section %d | Tile %d | Alignment: %s', sec.num, tile, alignment), 'Interpreter', 'none')

end

