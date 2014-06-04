function tiles = imload_section_tiles(sec, scale, wafer_path)
%IMLOAD_SECTION_TILES Loads and optionally rescales the tile images of a section.
% Usage:
%   tiles = imload_section_tiles(sec_struct)
%   tiles = imload_section_tiles(sec_num)
%   tiles = imload_section_tiles(sec, scale)
%   tiles = imload_section_tiles(sec, scale, wafer_path)

% Parameters
if nargin < 2
    scale = 1.0;
end
if nargin < 3
    wafer_path = waferpath;
end

% Get tile paths
tile_paths = get_tile_paths(sec, wafer_path);

% Load tiles in parallel
num_tiles = length(tile_paths);
tiles = cell(num_tiles, 1);
parfor t = 1:num_tiles
    % Load tile image from file
    tiles{t} = imread(tile_paths{t});

    % Resize if needed
    if scale ~= 1.0
        tiles{t} = imresize(tiles{t}, scale);
    end
end
end

