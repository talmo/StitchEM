function features = detect_section_features(tiles, rough_alignments, varargin)
%DETECT_SECTION_FEATURES Detects features in all the tiles of a section.

% Parse inputs
if nargin < 2
    rough_alignments = {};
end
[tiles, rough_alignments, params] = parse_inputs(tiles, rough_alignments, varargin{:});

total_time = tic;

% Initialize table with empty values
features = initialize_table(params.initial_rows, params.section_num);
num_features = 0;

% Loop through tiles
for tile_num = 1:length(tiles)
    tic;
    % Detect features in tile
    tile_features = detect_tile_features(tiles{tile_num});
    
    % Indexing
    num_tile_features = size(tile_features, 1);
    tile_idx = ((1:num_tile_features) + num_features)';
    num_features = num_features + num_tile_features;
    
    % Append tile features to section table
    features.id(tile_idx) = tile_idx;
    features.local_points(tile_idx, :) = tile_features.local_points;
    features.global_points(tile_idx, :) = rough_alignments{tile_num}.transformPointsForward(tile_features.local_points);
    features.descriptors(tile_idx, :) = tile_features.descriptors;
    features.tile(tile_idx, :) = repmat(tile_num, num_tile_features, 1);
    
    fprintf('Detected %d features in tile %d [%.2fs]\n', num_tile_features, tile_num, toc)
end

% Drop any empty rows
features = features(1:num_features, :);

fprintf('Detected %d features total (avg %.1f / tile). [%.2fs total]\n', num_features, num_features / length(tiles), toc(total_time))

end

function features_table = initialize_table(num_rows, section_num)
id = zeros(num_rows, 1);
local_points = zeros(num_rows, 2);
global_points = zeros(num_rows, 2);
descriptors = zeros(num_rows, 64);
section = repmat(section_num, num_rows, 1);
tile = zeros(num_rows, 1);

features_table = table(id, local_points, global_points, descriptors, section, tile);
end

function [tiles, rough_alignments, params] = parse_inputs(tiles, rough_alignments, varargin)
% Create inputParser instance
p = inputParser;

% Required parameters
p.addRequired('tiles');

% Just initialize to identity if no rough alignments are passed in.
% This means that the global points will be the same as the local points
p.addOptional('rough_alignments', num2cell(repmat(affine2d(), length(tiles), 1)));

% Number of rows to pre-allocate to feature table
p.addParameter('initial_rows', 30000);

% The section number to add to the table
p.addParameter('section_num', 0);

% Validate and parse input
p.parse(tiles, rough_alignments, varargin{:});
tiles = p.Results.tiles;
rough_alignments = p.Results.rough_alignments;
params = rmfield(p.Results, {'tiles', 'rough_alignments'});
end
