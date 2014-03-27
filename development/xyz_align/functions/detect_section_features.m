function sec = detect_section_features(sec, varargin)
%DETECT_SECTION_FEATURES Detects features in all the tiles of a section.
% Usage:
%   features = DETECT_SECTION_FEATURES(sec)
%   features = DETECT_SECTION_FEATURES(..., 'Name', Value)
%
% Name-Value pairs:
%   'detection_scale', 0.25
%   'verbosity', 1
% Any additional pairs will be passed to detect_tile_features().

% Parse inputs
[params, unmatched_params] = parse_inputs(varargin{:});

if params.verbosity > 0
    fprintf('== Detecting features for tiles in section %d.\n', sec.num)
end

total_time = tic;

% Initialize variables for parallelization
num_tiles = sec.num_tiles;
xy_tiles = sec.img.xy_tiles;
xy_prescale = sec.tile_xy_scale;
z_tiles = sec.img.z_tiles;
z_prescale = sec.tile_z_scale;
rough_alignments = sec.rough_tforms;

local_points_xy = cell(num_tiles, 1);
global_points_xy = cell(num_tiles, 1);
descriptors_xy = cell(num_tiles, 1);

local_points_z = cell(num_tiles, 1);
global_points_z = cell(num_tiles, 1);
descriptors_z = cell(num_tiles, 1);

r = @(i) ceil(i/ 4); c = @(i) mod(i - 1, 4) + 1;

if params.verbosity > 1
    fprintf('Initialized variables for parallelization. [%.2fs]\n', toc(total_time))
end

% Turn off warning about badly scaled or nearly singular matrix
warning('off', 'MATLAB:nearlySingularMatrix')

% Loop through tiles
for tile_num = 1:num_tiles
    tic;
    % Find regions overlapping with neighbors
    neighbors = arrayfun(@(i) sqrt((r(i) - r(tile_num)) .^ 2 +  (c(i) - c(tile_num)) .^ 2), 1:16) <= 1;
    overlap_regions = calculate_overlaps(rough_alignments(neighbors));
    
    % Convert to regions local coordinates
    overlap_regions = cellfun(@(x) rough_alignments{tile_num}.transformPointsInverse(x), overlap_regions, 'UniformOutput', false);
    
    % Detect XY features in tile
    tile_xy_features = detect_tile_features(xy_tiles{tile_num}, 'regions', overlap_regions, ...
        'detection_scale', params.xy_detection_scale, 'pre_scale', xy_prescale, ...
        'MetricThreshold', params.xy_MetricThreshold, unmatched_params);
    
    % Detect Z features in tile
    tile_z_features = detect_tile_features(z_tiles{tile_num}, ...
        'detection_scale', params.z_detection_scale, 'pre_scale', z_prescale, ...
        'MetricThreshold', params.z_MetricThreshold, unmatched_params);
    
    % Save data
    local_points_xy{tile_num} = tile_xy_features.local_points;
    global_points_xy{tile_num} = rough_alignments{tile_num}.transformPointsForward(tile_xy_features.local_points);
    descriptors_xy{tile_num} = tile_xy_features.descriptors;
    
    local_points_z{tile_num} = tile_z_features.local_points;
    global_points_z{tile_num} = rough_alignments{tile_num}.transformPointsForward(tile_z_features.local_points);
    descriptors_z{tile_num} = tile_z_features.descriptors;
    
    if params.verbosity > 1
        fprintf('Detected %d XY features and %d Z features in tile %d [%.2fs]\n', length(tile_xy_features.local_points), length(tile_z_features.local_points), tile_num, toc)
    end
end

% Turn warning about badly scaled or nearly singular matrix back on
warning('on', 'MATLAB:nearlySingularMatrix')

post_process_time = tic;

% Post-process output (XY)
tile_lengths_xy = cellfun('length', local_points_xy);
num_xy_features = sum(tile_lengths_xy);
id = (1:num_xy_features)';
local_points = vertcat(local_points_xy{:});
global_points = vertcat(global_points_xy{:});
descriptors = vertcat(descriptors_xy{:});
section = repmat(sec.num, num_xy_features, 1);
tile = cell2mat(arrayfun(@(t) repmat(t, tile_lengths_xy(t), 1), (1:length(tile_lengths_xy))', 'UniformOutput', false));

% Build table
sec.xy_features = table(id, local_points, global_points, descriptors, section, tile);


% Post-process output (Z)
tile_lengths_z = cellfun('length', local_points_z);
num_z_features = sum(tile_lengths_z);
id = (1:num_z_features)';
local_points = vertcat(local_points_z{:});
global_points = vertcat(global_points_z{:});
descriptors = vertcat(descriptors_z{:});
section = repmat(sec.num, num_z_features, 1);
tile = cell2mat(arrayfun(@(t) repmat(t, tile_lengths_z(t), 1), (1:length(tile_lengths_z))', 'UniformOutput', false));

% Build table
sec.z_features = table(id, local_points, global_points, descriptors, section, tile);


if params.verbosity > 1
    fprintf('Post-processed variables for output. [%.2fs]\n', toc(post_process_time))
end

if params.verbosity > 0
    fprintf('Detected %d XY features and %d Z features. [%.2fs]\n', num_xy_features, num_z_features, toc(total_time))
end
end

function [params, unmatched_params] = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true; % pass through to detect_tile_features

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
