function plot_alignment(alignment, tile_sz)
%PLOT_ALIGNMENT Plots the result of applying the alignment to a set of tiles.
% Usage:
%   plot_alignment(alignment)
%   plot_alignment(alignment, tile_sz)

[valid_alignment, alignment_name] = validatealignment(alignment);
if nargin < 2
    tile_sz = [8000, 8000];
end
PatchSpec = 'r0.1';

% Transformed bounding boxes
tiles = cellfun(@(t) t.transformPointsForward(sz2bb(tile_sz)), valid_alignment.tforms, 'UniformOutput', false);

% Plot
draw_polys(tiles, PatchSpec)

% Adjust the figure
grid on
axis equal ij
ax2int()
title_str = sprintf('\\bfAlignment\\rm: %s', alignment_name);
if isfield(alignment, 'meta') && isfield(alignment.meta, 'avg_post_error')
    title_str = sprintf('%s | \\bfError\\rm: %.3f px/match', title_str, alignment.meta.avg_post_error);
end
append_title(strrep(title_str, '_', '\_'))

end

