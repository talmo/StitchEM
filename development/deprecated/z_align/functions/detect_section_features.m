function features = detect_section_features(tiles, varargin)
%DETECT_SECTION_FEATURES Detects features in all the tiles of a section.
% Usage:
%   features = DETECT_SECTION_FEATURES(tiles)
%   features = DETECT_SECTION_FEATURES(tiles, pre_alignments) % pre_alignments is an array of transforms
%   features = DETECT_SECTION_FEATURES(..., 'Name', Value)
%
% Name-Value pairs:
%   'pre_scale', 1.0
%   'detection_scale', 0.25
%   'verbosity', 1
% Any additional pairs will be passed to detect_tile_features().

% Parse inputs
[tiles, pre_alignments, params, unmatched_params] = parse_inputs(tiles, varargin{:});

total_time = tic;

% Initialize variables for parallelization
num_tiles = length(tiles);
local_points = cell(num_tiles, 1);
global_points = cell(num_tiles, 1);
descriptors = cell(num_tiles, 1);
pre_scale = params.pre_scale;
detection_scale = params.detection_scale;
verbosity = params.verbosity;

if verbosity > 1
    fprintf('Initialized variables for parallelization. [%.2fs]\n', toc(total_time))
end

% Loop through tiles
parfor tile_num = 1:length(tiles)
    if verbosity > 1
        fprintf('Detecting: tile_num = %d | pre_scale = %s | detection_scale = %s \n', tile_num, num2str(pre_scale), num2str(detection_scale))
    end
    tic;
    % Detect features in tile
    tile_features = detect_tile_features(tiles{tile_num}, 'pre_scale', pre_scale, 'detection_scale', detection_scale, unmatched_params);
    
    % Save data
    local_points{tile_num} = tile_features.local_points;
    global_points{tile_num} = pre_alignments{tile_num}.transformPointsForward(tile_features.local_points);
    descriptors{tile_num} = tile_features.descriptors;
    
    if verbosity > 0
        fprintf('Detected %d features in tile %d [%.2fs]\n', length(tile_features.local_points), tile_num, toc)
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
section = repmat(params.section_num, num_features, 1);
tile = cell2mat(arrayfun(@(t) repmat(t, tile_lengths(t), 1), (1:length(tile_lengths))', 'UniformOutput', false));

if verbosity > 1
    fprintf('Post-processed variables for output. [%.2fs]\n', toc(post_process_time))
end

% Build table
features = table(id, local_points, global_points, descriptors, section, tile);

fprintf('Detected %d features total (avg %.1f / tile). [%.2fs total]\n', num_features, num_features / num_tiles, toc(total_time))

end

function [tiles, pre_alignments, params, unmatched_params] = parse_inputs(tiles, varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true; % pass through to detect_tile_features

% Required parameters
p.addRequired('tiles');

% These are the transforms from any pre-alignment steps.
% By default, transforms are initialized to identity. This means that the
% global points will be the same as the local points.
p.addOptional('pre_alignments', {});

% The section number to associate with these matches
p.addParameter('section_num', 0);

% The scale of the tile images that were inputed
p.addParameter('pre_scale', 1.0);

% The scale that we actually want to detect in (default = 0.25)
p.addParameter('detection_scale', 0.25);

% Debugging
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(tiles, varargin{:});
tiles = p.Results.tiles;
pre_alignments = p.Results.pre_alignments;
params = rmfield(p.Results, {'tiles', 'pre_alignments'});
unmatched_params = p.Unmatched;

% Initialize transform container if it's empty
if isempty(pre_alignments)
    pre_alignments = cell(length(tiles), 1);
end

% Fill in any missing trasforms by aligning to grid
if any(cellfun('isempty', pre_alignments))
    pre_alignments = estimate_tile_grid_alignments(pre_alignments);
end

end
