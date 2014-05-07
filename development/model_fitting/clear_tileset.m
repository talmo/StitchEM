function sec = clear_tileset(sec, tile_set)
%CLEAR_TILESET Removes a tileset from a section.
% Usage:
%   sec = clear_tileset(sec, tile_set)

sec = rmfield(sec.tiles, tile_set);

end

