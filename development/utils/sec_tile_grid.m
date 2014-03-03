function tile_grid = sec_tile_grid(sec_num, varargin)
%NUM_TILES_IN_SEC Returns a grid of tiles for the given section.

% Easy grid!
if nargin == 0
    tile_grid = reshape(1:16, 4, 4)';
    return
end

% Parse inputs
[sec_num, params] = parse_inputs(sec_num, varargin{:});

% Get section tile paths
tile_paths = get_tile_path(sec_num);

% General info
num_tiles = length(tile_paths);
last_tile_info = get_path_info(tile_paths{end});
grid_rows = last_tile_info.row;
grid_cols = last_tile_info.col;

switch params.grid_contents
    case 'index'
        tile_grid = 1:num_tiles;
    case 'filenames'
        tile_grid = find_tile_images(get_section_path(sec_num), false);
    case 'paths'
        tile_grid = tile_paths;
    case 'coordinates'
        tile_grid = cell(num_tiles, 1);
        for r = 1:grid_rows
            for c = 1:grid_cols
                tile_grid{(r-1) * 4 + c} = [r, c];
            end
        end
    case 'images'
        tile_grid = cell(num_tiles, 1);
        im_scale = params.image_scale;
        parfor i = 1:num_tiles
            tile_grid{i} = imshow_tile(sec_num, i, true, im_scale);
        end
    case 'tforms'
        tile_grid = repmat({affine2d()}, 16, 1);
end

% Shape into grid
tile_grid = reshape(tile_grid, grid_rows, grid_cols)';

end

function [sec_num, params] = parse_inputs(sec_num, varargin)
% Create inputParser instance
p = inputParser;

% Required parameters
p.addRequired('sec_num');

% Optional parameters
content_types = {'index', 'filenames', 'paths', 'coordinates', 'images', 'tforms'};
p.addOptional('grid_contents', 'index', @(x) any(strcmp(content_types, x)));

% Name-value pairs
p.addParameter('image_scale', 1.0);

% Validate and parse input
p.parse(sec_num, varargin{:});
sec_num = p.Results.sec_num;
params = rmfield(p.Results, 'sec_num');

end