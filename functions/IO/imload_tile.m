function tile_img = imload_tile(sec_num, tile_num, scale, wafer_path)
%IMLOAD_TILE Loads a tile given a section and tile number.

if nargin < 3
    scale = 1.0;
end
if nargin < 4
    wafer_path = waferpath;
end

% Get path to tile image
tile_path = get_tile_path(sec_num, tile_num, wafer_path);

% Load tile image from file
tile_img = imread(tile_path);

% Resize if needed
if scale ~= 1.0
    tile_img = imresize(tile_img, scale);
end
end

