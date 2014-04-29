function tiles = imload_section_tiles(sec_num, scale, wafer_path)
%IMLOAD_SECTION_TILES Loads and optionally rescales the tile images of a section.

% Parameters
if nargin < 2
    scale = 1.0;
end
if nargin < 3
    wafer_path = waferpath;
end

% Get the paths to the tile images
tile_paths = find_tiles(sec_num, true, wafer_path);

% Load tiles in parallel
num_tiles = length(tile_paths);
tiles = cell(num_tiles, 1);
parfor t = 1:num_tiles
    tiles{t} = imload_tile(sec_num, t, scale, wafer_path);
end
end

