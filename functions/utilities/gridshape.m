function [B, grid] = gridshape(A, grid)
%GRIDSHAPE Reshape an array to match the indices of a grid.
% Usage:
%   B = gridshape(A)
%   [B, grid] = gridshape(A)
%   B = gridshape(A, grid)
%
% Args:
%   A: an array to be reshaped
%   grid: a numeric array with the indices of the grid elements. If
%       omitted, a grid is generated based on the size of A.
%
% Returns:
%   B: an array where B(i, j) = A(grid(i, j)). This is a cell array if the
%       number of elements in A is less than the number of elements in the 
%       grid and will contain empty cells.
%   grid: the grid used or generated

if nargin < 2
    rows = ceil(sqrt(numel(A)));
    cols = ceil(numel(A) / rows);
    grid = reshape(1:rows*cols, cols, rows)';
end

% Convert to cell array if needed and pad with empty cells
if numel(A) < numel(grid)
    A = num2cell(A);
    A{numel(grid)} = [];
end

% Index as grid
B = A(grid);

end

