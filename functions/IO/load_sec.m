function sec = load_sec(sec_num, varargin)
% LOAD_SEC Loads a section and its images based on section number.
%
% Usage:
%   sec = LOAD_SEC(sec_num)
%   sec = LOAD_SEC(..., 'Name', Value)


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
sec.wafer = info.wafer;
sec.num_tiles = info.num_tiles;
sec.rows = info.rows;
sec.cols = info.cols;
sec.grid = info.grid;

% Alignments
sec.alignments.initial.tforms = repmat({affine2d()}, sec.num_tiles, 1);

% Tile sizes
sec.tile_sizes = arrayfun(@(t) get_tile_size(sec.num, t), 1:sec.num_tiles, 'UniformOutput', false)';

% Legacy fields
if params.legacy
    sec.rough_tforms = cell(sec.num_tiles, 1);
    sec.fine_tforms = cell(sec.num_tiles, 1);
    sec.grid_aligned = [];
    sec.xy_features = table();
    sec.z_features = table();
end

%% Image Loading
% Montage overview
load_overview_time = tic;
if params.legacy
    sec.overview_scale = params.overview_scale;
    sec.overview_tform = affine2d();
    sec.img.overview = imload_overview(sec.num, sec.overview_scale, params.wafer_path);
    sec.img.overview_scale = params.overview_scale;
else
    sec.overview.img = imload_overview(sec.num, params.overview_scale, params.wafer_path);
    sec.overview.size = imsize(get_overview_path(sec.num));
    sec.overview.scale = params.overview_scale;
    sec.overview.alignment.tform = affine2d();
    sec.overview.alignment.rel_to_sec = sec.num;
end
if params.verbosity > 0; fprintf('Loaded and resized overview image. [%.2fs]\n', toc(load_overview_time)); end

% Tiles
load_tiles_time = tic;

if params.legacy
    sec.tile_rough_scale = params.tile_rough_scale;
    sec.tile_z_scale = params.tile_z_scale;
    sec.tile_xy_scale = params.tile_xy_scale;
    
    sec.img.xy_tiles = imload_section_tiles(sec.num, sec.tile_xy_scale);
    sec.img.xy_tiles_scale = params.tile_xy_scale;

    sec.img.z_tiles = imload_section_tiles(sec.num, sec.tile_z_scale);
    sec.img.z_tiles_scale = params.tile_z_scale;

    sec.img.rough_tiles = imload_section_tiles(sec.num, sec.tile_rough_scale);
    sec.img.rough_tiles_scale = params.tile_rough_scale;
else
    for i = 1:2:length(params.scales)
        name = params.scales{i};
        scale = params.scales{i + 1};
        
        sec.tiles.(name).img = imload_section_tiles(sec.num, scale);
        sec.tiles.(name).scale = scale;
    end
end

if params.verbosity > 0; fprintf('Loaded and resized tile images. [%.2fs]\n', toc(load_tiles_time)); end
end

function params = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;

% Overview scaling
p.addParameter('overview_scale', 0.78);

% Tile scaling
default_scales = {'xy', 1.0, 'z', 0.125, 'rough', 0.07 * 0.78};
p.addParameter('scales', default_scales, @(x) isempty(x) || (iscell(x) && ~mod(numel(x), 2)))

% Tile scaling (legacy)
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

% Misc
p.addParameter('verbosity', 1);
p.addParameter('legacy', true);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

% Calculate tile rough scaling if needed (legacy)
if strcmp(params.tile_rough_scale, 'auto')
    params.tile_rough_scale = params.overview_scale * params.tile_rough_rel_scale;
end

% Default scaling if empty
if isempty(params.scales)
    params.scales = {'full', 1.0};
end
end
