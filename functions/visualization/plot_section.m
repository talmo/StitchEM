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
[alignment, alignment_name] = validatealignment(alignment, sec);

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
title_str = sprintf('\\bfSection\\rm: %s | \\bfAlignment\\rm: %s', sec.name, alignment_name);
if isfield(alignment, 'meta') && isfield(alignment.meta, 'avg_post_error')
    title_str = sprintf('%s | \\bfError\\rm: %.3f px/match', title_str, alignment.meta.avg_post_error);
end
append_title(strrep(title_str, '_', '\_'))
end

