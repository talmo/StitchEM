function plot_seams(tforms, scale)
%PLOT_SEAMS Plots the seams for a given set of tforms.

if nargin < 2
    scale = 1.0;
end

params.tile_size = [8000 8000];

% Compose tforms with scaling tform
tforms = cellfun(@(tform) compose_tforms(tform, make_tform('scale', scale)), tforms, 'UniformOutput', false);

% The points that define the boundaries of a tile form a polygon
tile = [0, 0;                    % top-left
        0, params.tile_size(2);  % top-right
        params.tile_size;        % bottom-right
        params.tile_size(2), 0]; % bottom-left
    
% Apply transforms to get the boundary polygons for each tile
tiles = cellfun(@(tform) tform.transformPointsForward(tile), tforms, 'UniformOutput', false);

% Plot bounds
hold on
colors = get(0,'DefaultAxesColorOrder');
for i = 1:length(tiles)
    X = [tiles{i}(:, 1); tiles{i}(1, 1)];
    Y = [tiles{i}(:, 2); tiles{i}(1, 2)];
    plot(X, Y, '-x', 'Color', colors(rem(i - 1, size(colors, 1)) + 1, :));
end

% Plot seam patches
seams = calculate_overlaps(tforms);
for i = 1:length(seams)
    patch(seams{i}(:,1), seams{i}(:,2), colors(rem(i - 1, size(colors, 1)) + 1, :), 'FaceAlpha', 0.5);
end

set(gca,'YDir','reverse');
integer_axes(1 / scale);

hold off
end

