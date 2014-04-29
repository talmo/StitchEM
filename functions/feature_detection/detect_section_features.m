function [sec, num_features_xy, num_features_z] = detect_section_features(sec, varargin)
%DETECT_SECTION_FEATURES Detects features in all the tiles of a section.
% Usage:
%   sec = DETECT_SECTION_FEATURES(sec)
%   sec = DETECT_SECTION_FEATURES(..., 'Name', Value)
%
% Name-Value pairs:
%   'detection_scale', 0.125
%   'verbosity', 1
% Any additional arguments will be passed to detect_tile_features().

% Parse inputs
[params, unmatched_params] = parse_inputs(varargin{:});

if params.verbosity > 0
    fprintf('== Detecting features for tiles in section %d.\n', sec.num)
end

total_time = tic;

% Initialize variables
num_tiles = sec.num_tiles;
rough_alignments = sec.rough_tforms;


if params.verbosity > 1
    fprintf('Initialized variables for parallelization. [%.2fs]\n', toc(total_time))
end

% Turn off warning about badly scaled or nearly singular matrix
warning('off', 'MATLAB:nearlySingularMatrix')
pctRunOnAll warning('off', 'MATLAB:nearlySingularMatrix')

%% XY
if any(strcmp(params.type, {'xy', 'xyz', 'both'}))
% Initialize variables
xy_tiles = sec.img.xy_tiles;
xy_prescale = sec.tile_xy_scale;

local_points_xy = cell(num_tiles, 1);
global_points_xy = cell(num_tiles, 1);
descriptors_xy = cell(num_tiles, 1);

% Detect XY features
parfor t = 1:num_tiles
    tile_time = tic;
    % Find regions overlapping with neighbors
    neighbors = find(find_neighbors(t));
    overlap_regions = calculate_overlaps(rough_alignments([t neighbors]));
    
    % Convert to regions local coordinates
    overlap_regions = cellfun(@(x) rough_alignments{t}.transformPointsInverse(x), overlap_regions, 'UniformOutput', false);
    
    % Detect XY features in tile
    tile_xy_features = detect_tile_features(xy_tiles{t}, 'regions', overlap_regions, ...
        'detection_scale', params.xy_detection_scale, 'pre_scale', xy_prescale, ...
        'MetricThreshold', params.xy_MetricThreshold, unmatched_params);
    
    % Save data
    local_points_xy{t} = tile_xy_features.local_points;
    global_points_xy{t} = rough_alignments{t}.transformPointsForward(tile_xy_features.local_points);
    descriptors_xy{t} = tile_xy_features.descriptors;
    
    if params.verbosity > 1
        fprintf('Detected %d XY features in tile %d [%.2fs]\n', height(tile_xy_features), t, toc(tile_time))
    end
end

% Post-process output (XY)
num_features_xy = cellfun('length', local_points_xy);
total_xy_features = sum(num_features_xy);
id = (1:total_xy_features)';
local_points = vertcat(local_points_xy{:});
global_points = vertcat(global_points_xy{:});
descriptors = vertcat(descriptors_xy{:});
section = repmat(sec.num, total_xy_features, 1);
tile = cell2mat(arrayfun(@(t) repmat(t, num_features_xy(t), 1), (1:length(num_features_xy))', 'UniformOutput', false));

% Build XY table
sec.xy_features = table(id, local_points, global_points, descriptors, section, tile);
end

%% Z
if any(strcmp(params.type, {'z', 'xyz', 'both'}))
% Initialize variables
local_points_z = cell(num_tiles, 1);
global_points_z = cell(num_tiles, 1);
descriptors_z = cell(num_tiles, 1);

z_tiles = sec.img.z_tiles;
z_prescale = sec.tile_z_scale;

% Detect Z features
for t = 1:num_tiles
    tile_time = tic;
    % Detect Z features in tile
    tile_z_features = detect_tile_features(z_tiles{t}, ...
        'detection_scale', params.z_detection_scale, 'pre_scale', z_prescale, ...
        'MetricThreshold', params.z_MetricThreshold, unmatched_params);
    
    % Save data
    local_points_z{t} = tile_z_features.local_points;
    global_points_z{t} = rough_alignments{t}.transformPointsForward(tile_z_features.local_points);
    descriptors_z{t} = tile_z_features.descriptors;
    
    if params.verbosity > 1
        fprintf('Detected %d Z features in tile %d [%.2fs]\n', height(tile_z_features), t, toc(tile_time))
    end
end

% Post-process output (Z)
num_features_z = cellfun('length', local_points_z);
total_z_features = sum(num_features_z);
id = (1:total_z_features)';
local_points = vertcat(local_points_z{:});
global_points = vertcat(global_points_z{:});
descriptors = vertcat(descriptors_z{:});
section = repmat(sec.num, total_z_features, 1);
tile = cell2mat(arrayfun(@(t) repmat(t, num_features_z(t), 1), (1:length(num_features_z))', 'UniformOutput', false));

% Build Z table
sec.z_features = table(id, local_points, global_points, descriptors, section, tile);
end
%%

% Turn warning about badly scaled or nearly singular matrix back on
warning('on', 'MATLAB:nearlySingularMatrix')
pctRunOnAll warning('on', 'MATLAB:nearlySingularMatrix')


if params.verbosity > 0
    switch params.type
        case {'xyz', 'both'}
            fprintf('Detected %d XY features and %d Z features. [%.2fs]\n', total_xy_features, total_z_features, toc(total_time))
        case 'xy'
            fprintf('Detected %d XY features. [%.2fs]\n', total_xy_features, toc(total_time))
        case 'z'
            fprintf('Detected %d Z features. [%.2fs]\n', total_z_features, toc(total_time))
    end
end
end

function [params, unmatched_params] = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true; % pass through to detect_tile_features

% Types of features
types = {'xy', 'z', 'both', 'xyz'};
p.addOptional('type', 'both', @(x) any(validatestring(x, types)));

% Debugging
p.addParameter('verbosity', 1);

% Detection scales
p.addParameter('xy_detection_scale', 1.0);
p.addParameter('z_detection_scale', 0.125);

% SURF parameters
p.addParameter('xy_MetricThreshold', 11000);
p.addParameter('z_MetricThreshold', 1000);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched_params = p.Unmatched;

end
