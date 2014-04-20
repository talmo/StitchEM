function varargout = imload_section_tiles(sec_num, tile_scales, wafer_path)
%IMLOAD_SECTION_TILES Loads and optionally rescales the tile images of a section.
% Usage:
%   tiles = IMLOAD_SECTION_TILES(sec_num)
%   [scaled_tiles, tiles] = IMLOAD_SECTION_TILES(sec_num, tile_scale)
%   [scaled_tiles, tiles] = IMLOAD_SECTION_TILES(sec_num, tile_scales)
% Notes:
%   - The second parameter, tile_scales, can be a single scalar value or a
%   cell array of scale values.

% Parameters
if nargin < 2
    tile_scales = {};
end
if nargin < 3
    wafer_path = '/data/home/talmo/EMdata/W002';
end

% Convert scales to cell array
if ~iscell(tile_scales)
    tile_scales = num2cell(tile_scales);
end

% Get rid of any scales == 1.0 (they don't need to be resized)
tile_scales(cellfun(@(x) x == 1.0, tile_scales)) = [];

% Get the paths to the images
tile_paths = get_tile_paths(sec_num, wafer_path);

% Initialize stuff for parallelization
num_tiles = length(tile_paths);
tiles = cell(num_tiles, 1);
scaled_tiles = cell(num_tiles, 1);
keep_full = nargout > 1;

% Load and resize tiles in parallel
parfor t = 1:num_tiles
    % Load full tile
    tile = imload_tile(sec_num, t, 1.0, wafer_path);
    if isempty(tile_scales) || keep_full
        tiles{t} = tile;
    end
    
    % Resize to each scale
    for s = 1:length(tile_scales)
        scaled_tiles{t}{s} = imresize(tile, tile_scales{s});
    end
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

