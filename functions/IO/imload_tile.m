function tile_img = imload_tile(sec, tile_num, scale, wafer_path)
%IMLOAD_TILE Loads a tile given a section and tile number.
% Usage:
%   tile_img = imload_tile(sec_struct, tile_num)
%   tile_img = imload_tile(sec_num, tile_num)
%   tile_img = imload_tile(sec_num, tile_num, scale)
%   tile_img = imload_tile(sec_num, tile_num, scale, wafer_path)
%
% Args:
%   sec_struct: a section structure created by load_section()
%   sec_num: the section number
%   scale: optionally scales the tile (default = 1.0)
%   wafer_path: path to the section's wafer folder (default = waferpath())
%
% Note: If a section structure is specified, this function will load the
%   tile from the tile_paths or tile_files field if found.
%
% See also: load_section

% Defaults
if nargin < 3; scale = 1.0; end
if nargin < 4; wafer_path = waferpath(); end

% Get tile path
tile_path = get_tile_path(sec, tile_num, wafer_path);

% Load tile image from file
tile_img = imread(tile_path);

% Resize if needed
if scale ~= 1.0
    tile_img = imresize(tile_img, scale);
end
end

