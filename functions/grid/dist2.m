function [dI, dJ] = dist2(t1, t2, grid, p)
%DIST2 Find distance of one tile to another in a grid.
% Usage:
%   d = dist2(t1, t2, grid)
%   d = dist2(t1, t2, grid, p)
%   [dI, dJ] = dist2(t1, t2, grid)
%
% See also: grid_neighbors, griddist

if nargin < 4
    p = 2;
end

% Get grid coordinates
[i, j] = find(grid == t1);
[u, v] = find(grid == t2);

% Calculate displacements
dI = u - i;
dJ = v - j;

if nargout < 2
    % Calculate distance
    dI = norm([dI, dJ], p);
    dJ = [];
end
end

