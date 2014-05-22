function sec = load_tileset(sec, scale_name, scale)
%LOAD_TILESET Loads a tile set at the specified scale.
% Usage:
%   sec = load_tileset(sec, scale_name, scale)

load_tiles_time = tic;

sec.tiles.(scale_name).img = imload_section_tiles(sec.num, scale);
sec.tiles.(scale_name).scale = scale;

fprintf('Loaded tile set ''%s'' (%sx) in section %d. [%.2fs]\n', scale_name, num2str(scale), sec.num, toc(load_tiles_time))

end

