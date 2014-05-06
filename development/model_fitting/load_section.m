function sec = load_section(sec_num, varargin)
%LOAD_SECTION Loads a section and its images based on section number.
% Usage:
%   sec = load_section(sec_num)

%% Parse inputs
params = parse_inputs(varargin{:});
if params.verbosity > 0; fprintf('== Loading section %d.\n', sec_num); end

%% Path info
info = get_path_info(get_section_path(sec_num, params.wafer_path));

%% Cache
%features_cache = fullfile(params.cache_path, 'features', [info.name '.mat']);
%TODO

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

%% Image Loading
% Montage overview
load_overview_time = tic;
sec.overview.img = imload_overview(sec.num, params.overview_scale, params.wafer_path);
sec.overview.size = imsize(get_overview_path(sec.num));
sec.overview.scale = params.overview_scale;
sec.overview.alignment.tform = affine2d();
sec.overview.alignment.rel_tform = affine2d();
sec.overview.alignment.rel_to_sec = sec.num;
if params.verbosity > 0; fprintf('Loaded and resized overview image. [%.2fs]\n', toc(load_overview_time)); end

% Tiles
load_tiles_time = tic;
for i = 1:2:length(params.scales)
    name = params.scales{i};
    scale = params.scales{i + 1};

    sec.tiles.(name).img = imload_section_tiles(sec.num, scale);
    sec.tiles.(name).scale = scale;
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

% Wafer path
p.addParameter('wafer_path', waferpath);

% Misc
p.addParameter('verbosity', 1);
p.addParameter('legacy', true);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

% Default scaling if empty
if isempty(params.scales)
    params.scales = {'full', 1.0};
end
end
