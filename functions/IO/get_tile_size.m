function sz = get_tile_size(sec_num, tile_num, wafer_path)
%GET_TILE_SIZE Returns the [rows, cols] of a tile.
% Usage:
%   sz = get_tile_size(sec_num, tile_num)
%   sz = get_tile_size(sec_num, tile_num, wafer_path)
%
% Returns:
%   sz is the [height, width] in pixels of the tile.
%
% See also: imsize, imfinfo, get_tile_path

if nargin < 3
    wafer_path = waferpath;
end

tile_path = get_tile_path(sec_num, tile_num, wafer_path);
sz = imsize(tile_path);

end

