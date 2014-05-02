function subs = regionToSubscripts(region, sz)
%REGIONTOSUBSCRIPTS Converts a region to subscripts of an image.
%
% Usage:
%   [rows, cols] = regionToSubscripts(region, sz)
%
% Args:
%   region is a 5x2 matrix with the 4 vertices of the region in intrinsic
%       image coordinates.
%   sz is the size of the image in [rows, cols] format.
%
% Returns:
%   subs is a 4x2 matrix of the top-left and bottom-right subscript
%       coordinates of the bounding box of the region.
%
% See also: intrinsicToSubscripts

% Get region bounds
X = [min(region(:, 1)); max(region(:, 1))];
Y = [min(region(:, 2)); max(region(:, 2))];

% Find subscripts of the bounds
subs = intrinsicToSubscripts([X Y], sz);

end

