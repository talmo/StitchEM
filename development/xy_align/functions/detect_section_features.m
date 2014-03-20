function features = detect_section_features(sec, varargin)
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

total_time = tic;

% Initialize variables for parallelization
num_tiles = sec.num_tiles;
tiles = sec.img.tiles;
rough_alignments = sec.rough_alignments;
verbosity = params.verbosity;
local_points = cell(num_tiles, 1);
global_points = cell(num_tiles, 1);
descriptors = cell(num_tiles, 1);
r = @(i) ceil(i/ 4); c = @(i) mod(i - 1, 4) + 1;

if verbosity > 1
    fprintf('Initialized variables for parallelization. [%.2fs]\n', toc(total_time))
end

% Loop through tiles
parfor tile_num = 1:16
    tic;
    % Find regions overlapping with neighbors
    neighbors = arrayfun(@(i) sqrt((r(i) - r(tile_num)) .^ 2 +  (c(i) - c(tile_num)) .^ 2), 1:16) <= 1;
    overlap_regions = calculate_overlaps(rough_alignments(neighbors));
    
    % Convert to regions local coordinates
    overlap_regions = cellfun(@(x) rough_alignments{tile_num}.transformPointsInverse(x), overlap_regions, 'UniformOutput', false);
    
    % Detect features in tile
    tile_features = detect_tile_features(tiles{tile_num}, 'regions', overlap_regions, 'detection_scale', 1.0, unmatched_params);
    
    % Save data
    local_points{tile_num} = tile_features.local_points;
    global_points{tile_num} = rough_alignments{tile_num}.transformPointsForward(tile_features.local_points);
    descriptors{tile_num} = tile_features.descriptors;
    
    if verbosity > 0
        fprintf('Detected %d features in %d regions in tile %d [%.2fs]\n', length(tile_features.local_points), length(overlap_regions), tile_num, toc)
    end
end

post_process_time = tic;

% Post-process output
tile_lengths = cellfun('length', local_points);
num_features = sum(tile_lengths);
id = (1:num_features)';
local_points = vertcat(local_points{:});
global_points = vertcat(global_points{:});
descriptors = vertcat(descriptors{:});
section = repmat(sec.num, num_features, 1);
tile = cell2mat(arrayfun(@(t) repmat(t, tile_lengths(t), 1), (1:length(tile_lengths))', 'UniformOutput', false));

if verbosity > 1
    fprintf('Post-processed variables for output. [%.2fs]\n', toc(post_process_time))
end

% Build table
features = table(id, local_points, global_points, descriptors, section, tile);

fprintf('Detected %d features total (avg %.1f / tile). [%.2fs total]\n', num_features, num_features / num_tiles, toc(total_time))

end

function [params, unmatched_params] = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true; % pass through to detect_tile_features

% Debugging
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched_params = p.Unmatched;

end
