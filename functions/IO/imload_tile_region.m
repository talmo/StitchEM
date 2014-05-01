function tile_region_img = imload_tile_region(sec_num, tile_num, region, scale, wafer_path)
%IMLOAD_TILE_REGION Loads a region of a tile given a section and tile number.
% Region types:
%   Bounding box: 5x2 matrix
%   Limits: 2x2 matrix, first row is XLimits, second row is YLimits
%   Spatial reference: imref2d object, see crop_imref2d
%   Position + size: 1x4 matrix, [x, y, width, height]
%
% See also: crop_imref2d, ref_bb, sz2bb, imload_tile

if nargin < 4
    scale = 1.0;
end
if nargin < 5
    wafer_path = waferpath;
end

% Get path to tile image
tile_path = get_tile_path(sec_num, tile_num, wafer_path);

% Convert region to rows and cols
if all(size(region) == [5, 2])
    cols = [min(region(:,1)), max(region(:,1))];
    rows = [min(region(:,2)), max(region(:,2))];
elseif all(size(region) == [2, 2])
    cols = region(1,:);
    rows = region(2,:);
elseif isa(region, 'imref2d')
    R = imref2d(get_tile_size(sec_num, tile_num));
    [I, J] = R.worldToSubscript(region.XWorldLimits, region.YWorldLimits);
    cols = J;
    rows = I;
elseif all(size(region) == [1, 4])
    cols = [region(1), region(1) + region(3)];
    rows = [region(2), region(2) + region(4)];
end

% Load region
tile_region_img = imread(tile_path, 'PixelRegion', {rows, cols});

% Resize if needed
if scale ~= 1.0
    tile_region_img = imresize(tile_region_img, scale);
end

end

