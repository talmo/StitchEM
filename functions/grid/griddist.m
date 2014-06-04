function [dI, dJ] = griddist(i, j, grid_sz, p)
%GRIDDIST Returns the distance from the specified coordinate to each grid point.
% Usage:
%   dists = griddist(idx, grid_sz)
%   dists = griddist(i, j, grid_sz)
%   dists = griddist(subs, grid_sz)
%   dists = griddist(..., p)
%   [dI, dJ] = griddist(...)
%
% Args (grid is a 2d array):
%   idx: scalar index, i.e., grid(idx)
%   i, j: subscripts, i.e., grid(i, j)
%   subs: subscript vector, i.e., grid(subs(1), subs(2))
%   grid_sz: size of the grid, i.e., size(grid)
%   p: use p-norm for distance calculation (default = 2)
%
% Returns:
%   dists: distance to each grid coordinate, where:
%       dists(u, v) = norm([u, v] - [i, j], p);
%   dI, dJ: displacements to each coordinate, where:
%       dI(u, :) = u - i; dJ(:, v) = v - j;
%
% All return values have the same size as the grid.
%
% See also: grid_neighbors

% Validate arguments
narginchk(2, 4)
if nargin < 4
    p = 2;
    if nargin == 3 && isscalar(grid_sz)
        p = grid_sz;
        grid_sz = j;
    end
    if isscalar(i)
        [i, j] = ind2sub(grid_sz, i);
        disp([i, j])
    else
        j = i(2);
        i = i(1);
    end
end
validateattributes(grid_sz, {'numeric'}, {'numel', 2}, mfilename, 'grid_sz')
validateattributes(i, {'numeric'}, {'scalar', '>', 0, '<=', grid_sz(1)}, mfilename, 'i')
validateattributes(j, {'numeric'}, {'scalar', '>', 0, '<=', grid_sz(2)}, mfilename, 'j')
validateattributes(j, {'numeric'}, {'scalar', '>', 0}, mfilename, 'p')

% Find displacements relative to [i, j]
[dJ, dI] = meshgrid((1:grid_sz(2)) - j, (1:grid_sz(1)) - i);

if nargout < 2
    % Find distances using p-norm
    dI = (abs(dI) .^ p + abs(dJ) .^ p) .^ (1 / p);
    % Euclidean distance
    %dI = sqrt(dI .^ 2 + dJ .^ 2);
    dJ = [];
end

end

