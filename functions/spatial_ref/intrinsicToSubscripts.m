function subs = intrinsicToSubscripts(pts, sz)
%INTRINSICTOSUBSCRIPTS Converts intrinsic coordinates to subscripts.
%
% Usage:
%   subs = intrinsicToSubscripts(pts, sz)
%
% Args:
%   pts is an Mx2 numeric array of intrinsic points.
%   sz is the size of the image.
%
% Returns:
%   subs is an Mx2 numeric array of [row, col] coordinates.
%
% Note: The output of this function is consistent with how imref2d
% estimates subscripts (SpatialDimensionManager).
%
% See also: regionToSubscripts, imref2d

%                Row                         Col
subs = [min(round(pts(:, 2)), sz(1)), min(round(pts(:, 1)), sz(2))];

end

