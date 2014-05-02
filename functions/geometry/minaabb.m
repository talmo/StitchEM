function varargout = minaabb(X, Y)
%MINAABB Computes the vertices of the minimum axis-aligned bounding box (AABB) of a set of points.
% Returns a set of points, the closed polygonal chain, which are the
% vertices of the minimum area axis aligned bounding box (AABB) around
% the given points.
%
% Usage:
%   V = minaabb(P)
%   V = minaabb(X, Y)
%   [Vx, Vy] = minaabb(P)
%   [Vx, Vy] = minaabb(X, Y)
%
% Args:
%   P is a vector of M points and must be a Mx2 or 2xM matrix.
%       Note: If P is a 2x2 matrix, it is assumed to be a vertical vector,
%       i.e, of the form: P = [x1, y1; x2, y2].
%   Alternatively, you can specify the points in two vectors:
%   [X, Y] must be Mx1 or 1xM coordinate vectors of the same length.
%
% Returns (default):
%   V is a 5x2 matrix of the vertices of the minimum AABB.
%   If there are two output targets:
%   [Vx, Vy] are 5x1 column vectors of the x and y components of V.
%   Notes:
%       - The points in V form a closed polygonal chain.
%           => Closed implies that the last point is the same as the first.
%       - The points are the vertices of the minimum AABB (a rectangle).
%       - The points are are specified counter-clockwise starting at the
%         bottom-left vertex.
%
% Misc. Notes:
%   - This is also known as the minimum bounding rectangle (MBR).
%   - This is NOT the minimum bounding box that contains the points!
%   Smaller bounding boxes can likely be found by computing arbitrarily
%   oriented minimum boxes (OMMBs). These can be further minimized by
%   removing the constraint that the boxes be rectangles. Other convex
%   quadrangles may be even smaller bounding boxes.
%
% Resources:
%   - http://www.datagenetics.com/blog/march12014/index.html
%   - http://geidav.wordpress.com/2014/01/23/computing-oriented-minimum-bounding-boxes-in-2d/
%   - http://en.wikipedia.org/wiki/Minimum_bounding_box
%   - http://www.mathworks.com/matlabcentral/fileexchange/34767-a-suite-of-minimal-bounding-objects
%
% See also: sz2bb, sec_bb, ref_bb, minboundrect, minboundrect

% Parse the inputs
if nargin == 1
    P = X;
elseif nargin == 2
    P = [X(:) Y(:)];
end

% Check size of points matrix
if (ndims(P) ~= 2 || ~any(size(P) == 2)) || (nargin == 2 && (~isvector(X) || ~isvector(Y)))
    error('Points must be specified as either a matrix of dimensions Mx2 or 2xM, or as a pair of Mx1 or 1xM coordinate vectors.')
end

% Convert non-square horizontal matrix to vertical coordinate matrix
if size(P, 1) == 2 && size(P, 2) ~= 2
    P = P';
end

% Calculate the boundaries of the points
min_x = min(P(:, 1));
min_y = min(P(:, 2));
max_x = max(P(:, 1));
max_y = max(P(:, 2));

% Build the closed polygonal chain of the minimum AABB counter-clockwise
V = [min_x, min_y;  % bottom-left
     max_x, min_y;  % bottom-right
     max_x, max_y;  % top-right
     min_x, max_y;  % top-left
     min_x, min_y]; % bottom-left (first vertex => closes the chain)

% Return the vertices
varargout = {V};
if nargout == 2
        varargout = {V(:, 1), V(:, 2)};
end
end

