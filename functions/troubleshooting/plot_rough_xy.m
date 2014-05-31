function plot_rough_xy(sec)
%PLOT_ROUGH_XY Plots the tiles of a section using its rough XY alignment. Colors tiles that were grid aligned differently.
% Usage:
%   plot_rough_xy(sec)

% Parameters
PatchSpec_grid = 'r0.1';
PatchSpec_registered = 'g0.1';

% Check for alignment
assert(isfield(sec.alignments, 'rough_xy'), 'Section must have a rough XY alignment.')

% Get bounding boxes
bounding_boxes = sec_bb(sec, 'rough_xy');

% Draw tiles
figure, hold on
for tile = 1:sec.num_tiles
    if any(sec.alignments.rough_xy.meta.grid_aligned == tile)
        draw_poly(bounding_boxes{tile}, PatchSpec_grid)
    else
        draw_poly(bounding_boxes{tile}, PatchSpec_registered)
    end
end

% Grid
% lims = min(vertcat(bounding_boxes{:}));
% overlap = sec.alignments.rough_xy.meta.assumed_overlap;
% xticks = [0; cumsum(cellfun(@(sz) sz(2) * (1-overlap), sec.tile_sizes(sec.grid(1,1:end-1))))] + lims(1);
% yticks = [0; cumsum(cellfun(@(sz) sz(1) * (1-overlap), sec.tile_sizes(sec.grid(1:end-1,1))))] + lims(2);
% grid on
% set(gca, 'XTick', xticks)
% set(gca, 'YTick', yticks)
grid on

% Adjust the figure
axis equal ij
ax2int()
title(sprintf('\\bfSection\\rm: %s | \\bfAlignment\\rm: rough\\_xy', strrep(sec.name, '_', '\_')))
append_title('{\bf\color{green}Green} = registered to overview | {\bf\color{red}Red} = grid aligned')
end

