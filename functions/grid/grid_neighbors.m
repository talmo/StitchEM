function neighbors = grid_neighbors(t, grid, max_dist)
%GRID_NEIGHBORS Returns a logical index array of neighbors of tile t in the grid.
% Usage:
%   neighbors = grid_neighbors(t, grid)
%   neighbors = grid_neighbors(t, grid, max_dist)
%
% Args:
%   t: tile number
%   grid: sec.grid
%   max_dist: threshold for the Euclidean distance of neighbors.
%       Defaults to 1. Set to sqrt(2) to include diagonal neighbors.
%
% See also: griddist

if nargin < 3
    max_dist = 1;
end

% Find the tile in the grid
[i, j] = find(grid == t, 1);

if isempty(i) || isempty(j); error('Tile %d was not found in the grid.', t); end

% Get distance of each grid coordinate to the tile's coordinate
dists = griddist(i, j, size(grid), 2);

% Find coords below threshold distance that are not empty, excluding self
neighbors = dists <= max_dist & dists > 0 & grid;

end

