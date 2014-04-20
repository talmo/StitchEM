function [tile_img, tile_img_spatial_ref, tile_path] = imload_tile(section_num, tile_num, scale, wafer_path)
%IMLOAD_TILE Loads a tile given a section and tile number.

if nargin < 3
    scale = 1.0;
end
if nargin < 4
    wafer_path = '/data/home/talmo/EMdata/W002';
end

% Find path to tile image
tile_path = get_tile_path(section_num, tile_num, wafer_path);

% Load tile image from file
tile_img = imread(tile_path);

% Resize if needed
if scale ~= 1.0
    tile_img = imresize(tile_img, scale);
end

% Create default spatial reference
tile_img_spatial_ref = imref2d(size(tile_img));

end

