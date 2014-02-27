function features = detect_section_features(sec_num, rough_alignment_tform, parameters)
%DETECT_SECTION_FEATURES Detects features in all the tiles of a section.

%% Parameters
params.initial_rows = 30000;

if nargin < 2
    rough_alignment_tform = affine2d();
end

if nargin > 2
    params = overwrite_defaults(params, parameters);
end

%% Detect features
fprintf('== Detecting features in section %d.\n', sec_num)

% Initialize table with empty values
tic;
features = initialize_table(params.initial_rows);
toc
num_features = 0;

% Loop through tiles
for tile_num = 1:16
    % Detect features in tile
    tile_features = detect_tile_features(sec_num, tile_num);
    
    % Indexing
    num_tile_features = size(tile_features, 1);
    tile_idx = ((1:num_tile_features) + num_features)';
    num_features = num_features + num_tile_features;
    
    % Append tile features to section table
    features.id(tile_idx) = tile_idx;
    features.local_points(tile_idx, :) = tile_features.local_points;
    features.global_points(tile_idx, :) = rough_alignment_tform.transformPointsForward(tile_features.local_points);
    features.descriptors(tile_idx, :) = tile_features.descriptors;
    features.section(tile_idx, :) = repmat(sec_num, num_tile_features, 1);
    features.tile(tile_idx, :) = repmat(tile_num, num_tile_features, 1);
end

% Drop empty rows

end

function features_table = initialize_table(num_rows)
id = zeros(num_rows, 1);
local_points = zeros(num_rows, 2);
global_points = zeros(num_rows, 2);
descriptors = zeros(num_rows, 64);
section = zeros(num_rows, 1);
tile = zeros(num_rows, 1);

features_table = table(id, local_points, global_points, descriptors, section, tile);
end