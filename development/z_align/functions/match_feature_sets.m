function [matchesA, matchesB, regions, region_data] = match_feature_sets(featuresA, featuresB, varargin)
%MATCH_FEATURE_SETS Returns matching points across two sections.

% Parse inputs
[featuresA, featuresB, params] = parse_inputs(featuresA, featuresB, varargin{:});

% Find bounds of area spanned by features
xy_top_left = max([min(featuresA.global_points); min(featuresB.global_points)]);
xy_bottom_right = min([max(featuresA.global_points); max(featuresB.global_points)]);

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
    'VariableNames', {'region', 'num_featsA', 'num_featsB', 'num_matches', 'distances'});
total_matching_time = tic;

% Loop through list of regions
matchesA = cell(num_regions, 1);
matchesB = cell(num_regions, 1);

for i = 1:num_regions
    tic;
    % Get features in region
    region_featuresA = filter_features(featuresA, 'global_points', [regions{i}, params.region_size, params.region_size]);
    region_featuresB = filter_features(featuresB, 'global_points', [regions{i}, params.region_size, params.region_size]);
    
    % Check if we have enough features
    if size(region_featuresA, 1) < 5 || size(region_featuresB, 1) < 5
        %fprintf('Skipped region %d/%d since there were not enough features to match. [%.2fs]\n', i, num_regions, toc)
        continue
    end
    
    % Match using NNR
    match_indices = matchFeatures(region_featuresA.descriptors, region_featuresB.descriptors, ...
        'MatchThreshold', params.MatchThreshold, ...
        'Method', params.Method, ...
        'Metric', params.Metric, ...
        'MaxRatio', params.MaxRatio);
    
    if size(match_indices, 1) == 0
        %fprintf('No matches found in region %d/%d. [%.2fs]\n', i, num_regions, toc)
        continue
    end
    
    % Get the rows corresponding to the matched features
    matchesA{i} = region_featuresA(match_indices(:, 1), {'id', 'global_points', 'section', 'tile'});
    matchesB{i} = region_featuresB(match_indices(:, 2), {'id', 'global_points', 'section', 'tile'});
    
    % Statistics
    ptsA = matchesA{i}.global_points;
    ptsB = matchesB{i}.global_points;
    num_matches = size(ptsA, 1);
    avg_distances = sum(calculate_match_distances(ptsA, ptsB)) / num_matches;
    % 'num_featsA', 'num_featsB', 'num_matches', 'distances'
    region_data_row = {size(region_featuresA, 1), size(region_featuresB, 1), num_matches, avg_distances};
    region_data(i, 2:end) = region_data_row;
    
    if params.verbosity > 1
        fprintf('feats: %d & %d -> %d matches | avg_dist = %.2f px | ', region_data_row{:})
    end
    
    if params.verbosity > 0
        fprintf('Matched region %d/%d. [%.2fs]\n', i, num_regions, toc)
    end
end

% Merge cell arrays into a single table per feature set
matchesA = vertcat(matchesA{:});
matchesB = vertcat(matchesB{:});

num_matches = size(matchesA, 1);
fprintf('Done NNR matching. Found %d matching features in %d regions. [%.2fs]\n', num_matches, num_regions, toc(total_matching_time))

%% GMM Clustering
if params.filter_inliers
    tic
    % Try to fit N Gaussians
    N = params.GMClusters;

    % Throw error instead of warning if we fail to converge during fit
    %s = warning('error', 'stats:gmdistribution:FailedToConvergeReps');

    % Calculate distances between the previous matches
    distances = calculate_match_distances(matchesA.global_points, matchesB.global_points);
    figure, hist(distances)
    % Calculate fit of Gaussian models
    fit = gmdistribution.fit(distances, N, 'Replicates', params.GMReplicates);

    % Return failure to converge to warning level
    %warning(s);

    % Cluster based on calculated models
    clusters_idx = cluster(fit, distances);

    % Find cluster with lowest mean
    cluster_means = zeros(N, 1);
    for n = 1:N
        cluster_means(n) = mean(distances(clusters_idx == n));
        fprintf('Detected inlier cluster %D: n = %d, mean = %.2f\n', n, sum(clusters_idx == n), cluster_means(n))
    end
    [~, c] = min(cluster_means);

    % Inliers are the matches in the cluster with the lowest mean
    inlier_indices = (clusters_idx == c);
    
    % Filter out outliers
    matchesA = matchesA(inlier_indices, :);
    matchesB = matchesB(inlier_indices, :);
    
    fprintf('Filtered using GMM. Inliers: %d/%d. [%.2fs]\n', length(inlier_indices), num_matches, toc)
end

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

function [featuresA, featuresB, params] = parse_inputs(featuresA, featuresB, varargin)
% Create inputParser instance
p = inputParser;

% Required parameters
p.addRequired('featuresA');
p.addRequired('featuresB');

% Regions
p.addParameter('region_size', 1500);

% Nearest Neighbor Ratio (matchFeatures)
p.addParameter('Prenormalized', true); % MATLAB default = false (SURF descriptors are already normalized)
p.addParameter('Method', 'NearestNeighborRatio'); % MATLAB default = 'NearestNeighborRatio'
p.addParameter('Metric', 'SSD'); % MATLAB default = 'SSD'
p.addParameter('MatchThreshold', 0.9); % MATLAB default = 1.0
p.addParameter('MaxRatio', 0.7); % MATLAB default = 0.6

% GMM Clustering
p.addParameter('filter_inliers', true);
p.addParameter('GMClusters', 2); % default = 2
p.addParameter('GMReplicates', 5); % default = 5


% Debugging and visualization
p.addParameter('verbosity', 0);
p.addParameter('show_region_stats', true);

% Validate and parse input
p.parse(featuresA, featuresB, varargin{:});
featuresA = p.Results.featuresA;
featuresB = p.Results.featuresB;
params = rmfield(p.Results, {'featuresA', 'featuresB'});
end