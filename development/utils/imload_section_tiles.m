function varargout = imload_section_tiles(sec_num, tile_scale, keep_full)
%IMLOAD_SECTION_TILES Loads and optionally rescales the tile images of a section.
% Usage:
%   tiles = imload_section_tiles(sec_num)
%   [scaled_tiles, tiles] = imload_section_tiles(sec_num, tile_scale)

% Parameters
if nargin < 2
    tile_scale = 1.0;
end
if nargin < 3
    keep_full = true;
end

% Get the paths to the images
tile_paths = get_tile_path(sec_num);

% Initialize stuff for parallelization
num_tiles = length(tile_paths);
tiles = cell(num_tiles, 1);

% We switch on this to minimize operations on nodes if we don't need to
% resize the images
if tile_scale == 1.0
    parfor tile_num = 1:num_tiles
        tiles{tile_num} = imload_tile(sec_num, tile_num);
    end
    varargout = {tiles};
else
    scaled_tiles = cell(num_tiles, 1);

    parfor tile_num = 1:num_tiles
        tiles{tile_num} = imload_tile(sec_num, tile_num);
        scaled_tiles{tile_num} = imresize(tiles{tile_num}, tile_scale);
        
        if ~keep_full
            tiles{tile_num} = [];
        end
    end
    varargout = {scaled_tiles, tiles};
end


end

