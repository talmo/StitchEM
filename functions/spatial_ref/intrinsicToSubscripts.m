function [I, J] = intrinsicToSubscripts(X, Y, sz)
%INTRINSICTOSUBSCRIPTS Converts intrinsic coordinates to subscripts.
%
% Usage:
%   [I, J] = intrinsicToSubscripts(X, Y, sz)
%   [I, J] = intrinsicToSubscripts(pts, sz)
%   IJ = intrinsicToSubscripts(...)
%
% Note: The output of this function is consistent with how imref2d
% estimates subscripts (SpatialDimensionManager), except that points that
% are out of bounds do not return NaNs, instead they are rounded to the
% closest subscript within the image.
%
% See also: imref2d

narginchk(2, 3)
if nargin == 2
    validateattributes(X, {'numeric'}, {'ncols', 2}, mfilename, 'pts', 1)
    sz = Y;
    Y = X(:, 2);
    X = X(:, 1);
end

I = max(min(round(Y), sz(1)), 1); % Rows
J = max(min(round(X), sz(2)), 1); % Cols

if nargout < 2
    I = [I(:), J(:)];
    J = [];
end

end

