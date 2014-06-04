function sec = load_tileset(sec, scale_name, scale)
%LOAD_TILESET Loads a tile set at the specified scale.
% Usage:
%   sec = load_tileset(sec, scale_name, scale)

load_tiles_time = tic;

% Check if we have another tile set we can just resize
closest = closest_tileset(sec, scale);
if ~isempty(closest)
    tiles = sec.tiles.(closest).img;
    prescale = sec.tiles.(closest).scale;
    
    % Resize
    parfor t = 1:length(tiles)
        tiles{t} = imresize(tiles{t}, scale / prescale);
    end
    tile_set.img = tiles;
    fprintf('Resized tile set ''%s'' (%sx) to ''%s'' (%sx) in %s. [%.2fs]\n', closest, num2str(prescale), scale_name, num2str(scale), sec.name, toc(load_tiles_time))
else
    tile_set.img = imload_section_tiles(sec, scale);
    fprintf('Loaded tile set ''%s'' (%sx) in %s. [%.2fs]\n', scale_name, num2str(scale), sec.name, toc(load_tiles_time))
end
tile_set.scale = scale;
sec.tiles.(scale_name) = tile_set;

end

