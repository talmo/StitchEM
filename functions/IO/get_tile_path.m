function tile_path = get_tile_path(sec_num, tile_num, wafer_path)
%GET_TILE_PATH Returns the path to a tile.

if nargin < 3
    wafer_path = waferpath;
end

tile_paths = find_tiles(sec_num, true, wafer_path);

if tile_num > length(tile_paths) || tile_num < 1
    error('Cannot find path to tile %d in section %d.', tile_num, sec_num)
end

% Return path to specified tile
tile_path = tile_paths{tile_num};

end

