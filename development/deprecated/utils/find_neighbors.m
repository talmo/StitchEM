function neighbors = find_neighbors(tile_num, grid_size)
%FIND_NEIGHBORS Returns a logical indexing array indicating a tile's neighbors.

if nargin < 2
    grid_size = [4 4];
end

% Index to row/col
r = @(i) ceil(i / grid_size(2));
c = @(i) mod(i - 1, grid_size(2)) + 1;

% Find neighbors
neighbors = arrayfun(@(i) sqrt((r(i) - r(tile_num)) .^ 2 +  (c(i) - c(tile_num)) .^ 2), 1:prod(grid_size)) == 1;
end

