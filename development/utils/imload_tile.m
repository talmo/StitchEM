function [tile_img, tile_img_spatial_ref, tile_path] = imload_tile(section_num, tile_num)
%IMLOAD_TILE Loads a tile given a section and tile number.

% Find path to tile image
tile_path = get_tile_path(section_num, tile_num);

% Load tile image from file
tile_img = imread(tile_path);
tile_img_spatial_ref = imref2d(size(tile_img));

end

