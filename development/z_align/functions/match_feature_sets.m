function [matches1, matches2, regions, region_data] = match_feature_sets(features1, features2, varargin)
%MATCH_FEATURE_SETS Returns matching points across two sections.

% Parse inputs
[features1, features2, params] = parse_inputs(features1, features2, varargin{:});

% Find bounds of area spanned by features
xy_top_left = max([min(features1.global_points); min(features2.global_points)]);
xy_bottom_right = min([max(features1.global_points); max(features2.global_points)]);

% Check for bad registration
width_height_ratio = max(xy_bottom_right - xy_top_left) / min(xy_bottom_right - xy_top_left);
if width_height_ratio < 0.8 || width_height_ratio > 1.2
    warning('Grid appears to be very rectangular. This is usually a sign of bad initialization.')
end

% Break area into smaller regions
[X, Y] = meshgrid(xy_top_left(1):params.region_size:xy_bottom_right(1), xy_top_left(2):params.region_size:xy_bottom_right(2));
regions = num2cell([X(:) Y(:)], 2);
num_regions = length(regions);

region_data = table(regions, zeros(num_regions, 1), zeros(num_regions, 1), zeros(num_regions, 1), zeros(num_regions, 1), ...
    'VariableNames', {'region', 'num_feats1', 'num_feats2', 'num_matches', 'distances'});
total_matching_time = tic;

% Loop through list of regions
matches1 = cell(num_regions, 1);
matches2 = cell(num_regions, 1);

for i = 1:num_regions
    tic;
    % Get features in region
    region_features1 = filter_features(features1, 'global_points', [regions{i}, params.region_size, params.region_size]);
    region_features2 = filter_features(features2, 'global_points', [regions{i}, params.region_size, params.region_size]);
    
    % Check if we have enough features
    if size(region_features1, 1) < 5 || size(region_features2, 1) < 5
        %fprintf('Skipped region %d/%d since there were not enough features to match. [%.2fs]\n', i, num_regions, toc)
        continue
    end
    
    % Match using NNR
    match_indices = matchFeatures(region_features1.descriptors, region_features2.descriptors, ...
        'MatchThreshold', params.MatchThreshold, ...
        'Method', params.Method, ...
        'Metric', params.Metric, ...
        'MaxRatio', params.MaxRatio);
    
    if size(match_indices, 1) == 0
        %fprintf('No matches found in region %d/%d. [%.2fs]\n', i, num_regions, toc)
        continue
    end
    
    % Get the rows corresponding to the matched features
    matches1{i} = region_features1(match_indices(:, 1), {'id', 'global_points', 'section', 'tile'});
    matches2{i} = region_features2(match_indices(:, 2), {'id', 'global_points', 'section', 'tile'});
    
    % Statistics
    pts1 = matches1{i}.global_points;
    pts2 = matches2{i}.global_points;
    num_matches = size(pts1, 1);
    avg_distances = sum(calculate_match_distances(pts1, pts2)) / num_matches;
    % 'num_feats1', 'num_feats2', 'num_matches', 'distances'
    region_data_row = {size(region_features1, 1), size(region_features2, 1), num_matches, avg_distances};
    region_data(i, 2:end) = region_data_row;
    
    if params.verbosity > 1
        fprintf('feats: %d & %d -> %d matches | avg_dist = %.2f px | ', region_data_row{:})
    end
    
    if params.verbosity > 0
        fprintf('Matched region %d/%d. [%.2fs]\n', i, num_regions, toc)
    end
end

% Merge cell arrays into a single table per feature set
matches1 = vertcat(matches1{:});
matches2 = vertcat(matches2{:});

fprintf('Done NNR matching. Found %d matching features in %d regions. [%.2fs]\n', size(matches1, 1), num_regions, toc(total_matching_time))

%% Visualization
if params.show_region_stats
    % Show number of matches heatmap
    figure,imagesc([xy_top_left(1), xy_bottom_right(1)], [xy_top_left(2), xy_bottom_right(2)], reshape(region_data.num_matches, size(X))), colorbar
    title('Number of matches')
    integer_axes()

    % Show match distance heatmap
    figure,imagesc([xy_top_left(1), xy_bottom_right(1)], [xy_top_left(2), xy_bottom_right(2)], reshape(region_data.distances, size(X))), colorbar
    title('Average match distances (px)')
    integer_axes()
end

end

function [features1, features2, params] = parse_inputs(features1, features2, varargin)
% Create inputParser instance
p = inputParser;

% Required parameters
p.addRequired('features1');
p.addRequired('features2');

% Regions
p.addParameter('region_size', 1500);

% Nearest Neighbor Ratio (matchFeatures)
p.addParameter('Prenormalized', true); % MATLAB default = false (SURF descriptors are already normalized)
p.addParameter('Method', 'NearestNeighborRatio'); % MATLAB default = 'NearestNeighborRatio'
p.addParameter('Metric', 'SSD'); % MATLAB default = 'SSD'
p.addParameter('MatchThreshold', 1.0); % MATLAB default = 1.0
p.addParameter('MaxRatio', 0.6); % MATLAB default = 0.6

% Debugging and visualization
p.addParameter('verbosity', 0);
p.addParameter('show_region_stats', true);

% Validate and parse input
p.parse(features1, features2, varargin{:});
features1 = p.Results.features1;
features2 = p.Results.features2;
params = rmfield(p.Results, {'features1', 'features2'});
end