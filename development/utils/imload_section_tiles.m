function varargout = imload_section_tiles(sec_num, tile_scales, keep_full)
%IMLOAD_SECTION_TILES Loads and optionally rescales the tile images of a section.
% Usage:
%   tiles = IMLOAD_SECTION_TILES(sec_num)
%   [scaled_tiles, tiles] = IMLOAD_SECTION_TILES(sec_num, tile_scale)
%   scaled_tiles = IMLOAD_SECTION_TILES(sec_num, tile_scale, keep_full)
%   [scaled_tiles, tiles] = IMLOAD_SECTION_TILES(sec_num, tile_scales)
% Notes:
%   - The second parameter, tile_scales, can be a single scalar value or a
%   cell array of scale values.
%   - The third parameter, keep_full, will not return the full tiles if set
%   to true.

% Parameters
if nargin < 2
    tile_scales = {};
end
if nargin < 3
    keep_full = true;
end
if ~iscell(tile_scales)
    tile_scales = {tile_scales};
end

% Get the paths to the images
tile_paths = get_tile_path(sec_num);

% Initialize stuff for parallelization
num_tiles = length(tile_paths);
tiles = cell(num_tiles, 1);
scaled_tiles = cell(num_tiles, 1);

% Load and resize tiles in parallel
for tile_num = 1:num_tiles
    % Load full tile
    tile = imload_tile(sec_num, tile_num);
    tiles{tile_num} = tile;
    
    % Resize to each scale
    scaled_tiles{tile_num} = cellfun(@(scale) {imresize(tile, scale)}, tile_scales);
end
scaled_tiles = vertcat(scaled_tiles{:});

% Set appropriate output argument
if ~isempty(tile_scales)
    if keep_full
        varargout = {scaled_tiles, tiles};
    else
        varargout = {scaled_tiles};
    end
else
    varargout = {tiles};
end

end

