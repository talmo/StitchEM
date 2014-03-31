function sec = load_sec(sec_num, varargin)
% LOAD_SEC Loads a section and its images based on section number.
% Usage:
%   sec = LOAD_SEC(sec_num)
%   sec = LOAD_SEC(..., 'Name', Value)
% Name-value pairs and defaults:
%   'overview_scale', 0.78
%   'tile_rough_scale', 'auto' % defaults to overview_scale * tile_rough_rel_scale
%   'tile_rough_rel_scale', 0.07
%   'tile_z_scale', 0.125
%   'tile_xy_scale', 1.0
%   'verbosity', 1

% Parse inputs
params = parse_inputs(varargin{:});

if params.verbosity > 0
    fprintf('== Loading section %d.\n', sec_num)
end

sec_path = get_section_path(sec_num);
[~, sec_name] = fileparts(sec_path);
sec_cache = fullfile(params.cache_path, [sec_name '.mat']);

% Check if section is in cache
if ~params.overwrite && exist(sec_cache, 'file')
    cache = load(sec_cache);
    sec = cache.sec;
    fprintf('Loaded section from cache. XY features: %d, Z features: %d.\n', height(sec.xy_features), height(sec.z_features))
    return
end

% Default values for a section structure
sec.num = sec_num;
sec.num_tiles = length(find_tile_images(get_section_path(sec_num)));
sec.path = sec_path;
sec.name = sec_name;
sec.overview_scale = params.overview_scale;
sec.tile_rough_scale = params.tile_rough_scale;
sec.tile_z_scale = params.tile_z_scale;
sec.tile_xy_scale = params.tile_xy_scale;
sec.overview_tform = affine2d();
sec.rough_tforms = cell(sec.num_tiles, 1);
sec.fine_tforms = cell(sec.num_tiles, 1);
sec.grid_aligned = [];
sec.xy_features = table();
sec.z_features = table();

% Load montage overview
load_overview_time = tic;
sec.img.overview = imresize(imload_overview(sec_num), sec.overview_scale);
if params.verbosity > 0
    fprintf('Loaded and resized overview image. [%.2fs]\n', toc(load_overview_time))
end

% Load tile images and resize them
load_tiles_time = tic;
scales = {sec.tile_rough_scale, sec.tile_z_scale};
[scaled_tiles, sec.img.xy_tiles] = imload_section_tiles(sec.num, scales);
sec.img.rough_tiles = scaled_tiles(:, 1);
sec.img.z_tiles = scaled_tiles(:, 2);
if params.verbosity > 0
    fprintf('Loaded and resized tile images. [%.2fs]\n', toc(load_tiles_time))
end
end

function params = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;

% Verbosity
p.addParameter('verbosity', 1);

% Scaling
p.addParameter('overview_scale', 0.78);
p.addParameter('tile_rough_scale', 'auto');
p.addParameter('tile_rough_rel_scale', 0.07);
p.addParameter('tile_z_scale', 0.125);
p.addParameter('tile_xy_scale', 1.0);

% Cache path
p.addParameter('cache_path', '/data/home/talmo/EMdata/W002/StitchData/sec_cache');
p.addParameter('overwrite', false);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

% Calculate tile rough scaling if needed
if strcmp(params.tile_rough_scale, 'auto')
    params.tile_rough_scale = params.overview_scale * params.tile_rough_rel_scale;
end
end
