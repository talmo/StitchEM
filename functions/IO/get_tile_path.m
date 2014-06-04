function tile_path = get_tile_path(sec, tile_num, wafer_path)
%GET_TILE_PATH Returns the path to an individual tile.
% Usage:
%   tile_path = get_tile_path(sec_num, tile_num)
%   tile_path = get_tile_path(sec_num, tile_num, wafer_path)
%
% See also: imload_tile, get_tile_paths

if nargin < 3
    wafer_path = waferpath;
end

% Get tile paths
tile_paths = get_tile_paths(sec, wafer_path);

if tile_num > length(tile_paths) || tile_num < 1
    error('Cannot find path to tile %d in section.', tile_num)
end

% Return path to specified tile
tile_path = tile_paths{tile_num};

end

