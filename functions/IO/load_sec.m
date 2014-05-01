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

%% Parse inputs
params = parse_inputs(varargin{:});
if params.verbosity > 0; fprintf('== Loading section %d.\n', sec_num); end

%% Path info
info = get_path_info(get_section_path(sec_num, params.wafer_path));
features_cache = fullfile(params.cache_path, 'features', [info.name '.mat']);

%% Cache
% Check if section is in cache
if params.from_cache && exist(features_cache, 'file')
    cache = load(features_cache);
    sec = cache.sec;
    fprintf('Loaded section features from cache. XY features: %d, Z features: %d.\n', height(sec.xy_features), height(sec.z_features))
    
    % Load tile images
    if params.load_tiles && (isempty(sec.img) || isempty(sec.img.xy_tiles))
        load_time = tic;
        sec.img.xy_tiles = imload_section_tiles(sec.num, sec.tile_xy_scale);
        sec.img.z_tiles = imload_section_tiles(sec.num, sec.tile_z_scale);
        sec.img.rough_tiles = imload_section_tiles(sec.num, sec.tile_rough_scale);
        fprintf('Loaded tile images. [%.2fs]\n', toc(load_time))
    end
    
    % Load section overview
    if params.load_overview && (isempty(sec.img) || isempty(sec.img.overview))
        load_overview_time = tic;
        sec.img.overview = imresize(imload_overview(sec_num), sec.overview_scale);
        fprintf('Loaded and resized overview image. [%.2fs]\n', toc(load_overview_time))
    end
    return
end

%% Section information and metadata
% Info
sec.num = sec_num;
sec.name = info.name;
sec.path = info.path;
sec.num_tiles = info.num_tiles;
sec.rows = info.rows;
sec.cols = info.cols;
sec.grid = info.grid;

% Alignments
sec.alignments.initial.tforms = repmat({affine2d()}, sec.num_tiles, 1);

% Tile sizes
sec.tile_sizes = arrayfun(@(t) get_tile_size(sec.num, t), 1:sec.num_tiles, 'UniformOutput', false)';

% Legacy
sec.overview_scale = params.overview_scale;
sec.tile_rough_scale = params.tile_rough_scale;
sec.tile_z_scale = params.tile_z_scale;
sec.tile_xy_scale = params.tile_xy_scale;
sec.rough_tforms = cell(sec.num_tiles, 1);
sec.fine_tforms = cell(sec.num_tiles, 1);
sec.grid_aligned = [];
sec.xy_features = table();
sec.z_features = table();

%% Image Loading
% Montage overview
sec.overview_tform = affine2d();
load_overview_time = tic;
sec.img.overview = imload_overview(sec.num, sec.overview_scale, params.wafer_path);
sec.img.overview_scale = params.overview_scale;
if params.verbosity > 0; fprintf('Loaded and resized overview image. [%.2fs]\n', toc(load_overview_time)); end

% Tiles
load_tiles_time = tic;

sec.img.xy_tiles = imload_section_tiles(sec.num, sec.tile_xy_scale);
sec.img.xy_tiles_scale = params.tile_xy_scale;

sec.img.z_tiles = imload_section_tiles(sec.num, sec.tile_z_scale);
sec.img.z_tiles_scale = params.tile_z_scale;

sec.img.rough_tiles = imload_section_tiles(sec.num, sec.tile_rough_scale);
sec.img.rough_tiles_scale = params.tile_rough_scale;

if params.verbosity > 0; fprintf('Loaded and resized tile images. [%.2fs]\n', toc(load_tiles_time)); end
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

% Cache
p.addParameter('cache_path', cachepath);
p.addParameter('from_cache', true);
p.addParameter('load_tiles', false);
p.addParameter('load_overview', false);

% Wafer path
p.addParameter('wafer_path', waferpath);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

% Calculate tile rough scaling if needed
if strcmp(params.tile_rough_scale, 'auto')
    params.tile_rough_scale = params.overview_scale * params.tile_rough_rel_scale;
end
end
