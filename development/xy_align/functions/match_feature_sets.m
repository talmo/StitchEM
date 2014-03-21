function [matchesA, matchesB, outliersA, outliersB] = match_feature_sets(featuresA, featuresB, varargin)
%MATCH_FEATURE_SETS Returns matching points across two sections.

% Parse inputs
params = parse_inputs(varargin{:});

total_matching_time = tic;

% Loop through list of regions
% matchesA = cell(num_regions, 1);
% matchesB = cell(num_regions, 1);

% parfor i = 1:num_regions
%     tic;
%     % Get features in region
%     region_featuresA = filter_features(featuresA, 'global_points', [regions{i}, params.region_size, params.region_size]);
%     region_featuresB = filter_features(featuresB, 'global_points', [regions{i}, params.region_size, params.region_size]);
%     
%     % Check if we have enough features
%     if size(region_featuresA, 1) < 5 || size(region_featuresB, 1) < 5
%         %fprintf('Skipped region %d/%d since there were not enough features to match. [%.2fs]\n', i, num_regions, toc)
%         continue
%     end
    
% Match using NNR
match_indices = matchFeatures(featuresA.descriptors, featuresB.descriptors, ...
    'MatchThreshold', params.MatchThreshold, ...
    'Method', params.Method, ...
    'Metric', params.Metric, ...
    'MaxRatio', params.MaxRatio);

% Get the rows corresponding to the matched features
matchesA = featuresA(match_indices(:, 1), {'id', 'global_points', 'section', 'tile'});
matchesB = featuresB(match_indices(:, 2), {'id', 'global_points', 'section', 'tile'});
    

if size(match_indices, 1) == 0
    fprintf('No matches found. [%.2fs]\n', toc)
    return
end
    % Statistics
    %ptsA = matchesA{i}.global_points;
    %ptsB = matchesB{i}.global_points;
    %num_matches = size(ptsA, 1);
    %avg_distances = sum(calculate_match_distances(ptsA, ptsB)) / num_matches;
    % 'num_featsA', 'num_featsB', 'num_matches', 'distances'
    %region_data_row = {size(region_featuresA, 1), size(region_featuresB, 1), num_matches, avg_distances};
    %region_data(i, 2:end) = region_data_row;
    
    %if params.verbosity > 1
    %    fprintf('feats: %d & %d -> %d matches | avg_dist = %.2f px | ', region_data_row{:})
    %end
    
%     if params.verbosity > 0
%         fprintf('Matched region %d/%d. [%.2fs]\n', i, num_regions, toc)
%     end
% end

% Merge cell arrays into a single table per feature set
% matchesA = vertcat(matchesA{:});
% matchesB = vertcat(matchesB{:});

num_matches = size(matchesA, 1);
if params.verbosity > 0
    fprintf('Found %d matching features. [%.2fs]\n', num_matches, toc(total_matching_time))
end


%% Inlier filtering
if ~params.filter_inliers
    outliersA = [];
    outliersB = [];
    return
end

tic
grid_inliers = zeros(num_matches, 1);
grid_outliers = zeros(num_matches, 1);

params.grid_aligned = {(1:16), (1:16)};

% Do the clustering for any grid-aligned tiles separately (they're
% probably mistranslated significantly)
if ~isempty(params.grid_aligned)
    % Filter per tile for the first feature set
    for i = 1:length(params.grid_aligned{1})
        % Find matches on this tile except what we already found to be outliers
        tile = params.grid_aligned{1}(i);
        grid_aligned_matches = matchesA.tile == tile & ~grid_outliers;

        % Filter for inliers if there are any matches on this tile
        if sum(grid_aligned_matches) >= 5
            % Get the matches
            grid_matchesA = matchesA(grid_aligned_matches, :);
            grid_matchesB = matchesB(grid_aligned_matches, :);

            % Filter
            [inliers_idx, outliers_idx] = filter_inliers(grid_matchesA, grid_matchesB, true, params);

            % Make logical indexing arrays
            grid_aligned_matches_idx = find(grid_aligned_matches);
            filtered_inliers = grid_aligned_matches; filtered_inliers(grid_aligned_matches_idx(outliers_idx)) = 0;
            filtered_outliers = grid_aligned_matches; filtered_outliers(grid_aligned_matches_idx(inliers_idx)) = 0;

            % Aggregate with existing classifications
            grid_inliers = grid_inliers | filtered_inliers;
            grid_outliers = grid_outliers | filtered_outliers;

            % Sanity checking
            assert(length(inliers_idx) + length(outliers_idx) == sum(grid_aligned_matches))
            assert(sum(filtered_inliers) + sum(filtered_outliers) == sum(grid_aligned_matches))
            assert(~any(arrayfun(@(i) any(outliers_idx == i), inliers_idx)))
            assert(~any(filtered_inliers & filtered_outliers))
            assert(~any(grid_inliers & grid_outliers))
        end
    end

    % Filter per tile for the second feature set
    for i = 1:length(params.grid_aligned{2})
        % Find matches on this tile except what we already found to be outliers
        tile = params.grid_aligned{2}(i);
        grid_aligned_matches = matchesB.tile == tile & ~grid_outliers;

        % Filter for inliers if there are any matches on this tile
        if sum(grid_aligned_matches) >= 5
            % Get the matches
            grid_matchesA = matchesA(grid_aligned_matches, :);
            grid_matchesB = matchesB(grid_aligned_matches, :);

            % Filter
            [inliers_idx, outliers_idx] = filter_inliers(grid_matchesA, grid_matchesB, true, params);

            % Make logical indexing arrays
            grid_aligned_matches_idx = find(grid_aligned_matches);
            filtered_inliers = grid_aligned_matches; filtered_inliers(grid_aligned_matches_idx(outliers_idx)) = 0;
            filtered_outliers = grid_aligned_matches; filtered_outliers(grid_aligned_matches_idx(inliers_idx)) = 0;

            % Aggregate with existing classifications
            grid_inliers = grid_inliers | filtered_inliers; 
            grid_outliers = grid_outliers | filtered_outliers;

            % Sanity checking
            assert(length(inliers_idx) + length(outliers_idx) == sum(grid_aligned_matches))
            assert(sum(filtered_inliers) + sum(filtered_outliers) == sum(grid_aligned_matches))
            assert(~any(arrayfun(@(i) any(outliers_idx == i), inliers_idx)))
            assert(~any(filtered_inliers & filtered_outliers))
        end
    end

    % If some matches were found to be both inliers and outliers, consider them outliers
    ambiguous_matches = grid_inliers & grid_outliers;
    grid_inliers(ambiguous_matches) = 0;
    grid_outliers(ambiguous_matches) = 1;

    if params.verbosity > 0
        fprintf('Filtered grid aligned tiles. Inliers: %d, Outliers: %d.\n', sum(grid_inliers), sum(grid_outliers))
    end

    % Sanity checking
    assert(sum(grid_inliers | grid_outliers) == sum(grid_inliers) + sum(grid_outliers))
    assert(~any(grid_inliers & grid_outliers))
end

% Find the rest of the matches that were from registered tiles
unfiltered_matches = ~(grid_inliers | grid_outliers);
unfilteredA = matchesA(unfiltered_matches, :);
unfilteredB = matchesB(unfiltered_matches, :);

% Check if everything was already filtered
if ~isempty(unfilteredA)
    % Filter
    [inliers_idx, outliers_idx] = filter_inliers(unfilteredA, unfilteredB, false, params);

    % Make logical indexing arrays
    unfiltered_matches_idx = find(unfiltered_matches);
    filtered_inliers = unfiltered_matches; filtered_inliers(unfiltered_matches_idx(outliers_idx)) = 0;
    filtered_outliers = unfiltered_matches; filtered_outliers(unfiltered_matches_idx(inliers_idx)) = 0;

    % Aggregate with grid matches
    inliers = grid_inliers | filtered_inliers;
    outliers = grid_outliers | filtered_outliers;
else
    % Grid matches were the only matches
    inliers = grid_inliers;
    outliers = grid_outliers;
end

% Separate matches
outliersA = matchesA(outliers, :);
outliersB = matchesB(outliers, :);
matchesA = matchesA(inliers, :);
matchesB = matchesB(inliers, :);
fprintf('Filtered registered matches. Total inliers: %d/%d. [%.2fs]\n', size(matchesA, 1), num_matches, toc)

% Sanity checking
assert(~any(inliers == outliers))
assert(sum(inliers) + sum(outliers) == num_matches)

end

function [inliers, outliers] = filter_inliers(matchesA, matchesB, gridded, params)
% Use Gaussian Mixture Model or k-means clustering to detect inliers based on
% distance.

% Calculate distances between the matches
distances = calculate_match_distances(matchesA.global_points, matchesB.global_points);

% Choose a filtering method
if gridded
    filter_method = params.filter_method_gridded;
else
    filter_method = params.filter_method;
end

switch filter_method
    case 'gm'
        try
            [inliers, outliers] = gm_cluster(distances, params);
        catch
            % Fallback to k-means if it fails
            [inliers, outliers] = k_means_cluster(distances, params);
        end
    case 'kmeans'
        [inliers, outliers] = k_means_cluster(distances, params);
end

% Angle filtering
if (~gridded && params.filter_angles) || (gridded && params.filter_angles_gridded)
    angles = points_self_angle(matchesA.global_points, matchesB.global_points);
    
    while abs(min(angles(inliers)) - max(angles(inliers))) > params.angle_tolerance
        % Get 'furthest' angle within inliers
        [~, idx_furthest] = max(mahal(angles(inliers), angles(inliers)));
        
        % Remove from inliers
        outliers = [outliers; inliers(idx_furthest)];
        inliers(idx_furthest) = [];
    end
end

end

function [inliers, outliers] = gm_cluster(distances, params)
% Try to fit 2 Gaussians
N = 2;

% Throw error instead of warning if we fail to converge or terminate early
warning('error', 'stats:gmdistribution:FailedToConvergeReps')
warning('error', 'stats:gmdistribution:IllCondCov');

% Calculate fit of Gaussian models
fit = gmdistribution.fit(distances, N, 'Replicates', params.gm_replicates);

% Return messages to warning level
warning('on', 'stats:gmdistribution:FailedToConvergeReps')
warning('on', 'stats:gmdistribution:IllCondCov');

% Cluster based on calculated models
clusters_idx = cluster(fit, distances);
clusters = unique(clusters_idx);

% Criteria for choosing the inlier cluster
switch params.gm_clustering_method
    case 'std'
        % Cluster with the smallest standard deviation
        stds = arrayfun(@(c) std(distances(clusters_idx == c)), clusters);
        [~, c] = min(stds);
    
    case 'mean'
        % Cluster with the smallest mean
        means = arrayfun(@(c) mean(distances(clusters_idx == c)), clusters);
        [~, c] = min(means);
        
    case 'largest'
        % Largest cluster
        sizes = arrayfun(@(c) length(distances(clusters_idx == c)), clusters);
        [~, c] = max(sizes);
end


% Split up by clusters
inliers = find(clusters_idx == c);
outliers = find(clusters_idx ~= c);
end

function [inliers, outliers] = k_means_cluster(distances, params)
% Two clusters: inliers and outliers
k = 2;

% Clustering
[clusters_idx, centroids] = kmeans(distances, k, 'replicates', params.kmeans_replicates);

clusters = 1:k;

% Criteria for choosing the inlier cluster
switch params.kmeans_clustering_method
    case 'std'
        % Cluster with the smallest standard deviation
        stds = arrayfun(@(c) std(distances(clusters_idx == c)), clusters);
        [~, c] = min(stds);
    
    case 'mean'
        % Cluster with the smallest mean
        means = arrayfun(@(c) mean(distances(clusters_idx == c)), clusters);
        [~, c] = min(means);
        
    case 'largest'
        % Largest cluster
        sizes = arrayfun(@(c) length(distances(clusters_idx == c)), clusters);
        [~, c] = max(sizes);
end

% Split up by clusters
inliers = find(clusters_idx == c);
outliers = find(clusters_idx ~= c);

end

function params = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;

% Regions
p.addParameter('region_size', 1500);

% Nearest Neighbor Ratio (matchFeatures)
p.addParameter('Prenormalized', true); % MATLAB default = false (SURF descriptors are already normalized)
p.addParameter('Method', 'NearestNeighborRatio'); % MATLAB default = 'NearestNeighborRatio'
p.addParameter('Metric', 'SSD'); % MATLAB default = 'SSD'
p.addParameter('MatchThreshold', 0.9); % MATLAB default = 1.0
p.addParameter('MaxRatio', 0.7); % MATLAB default = 0.6

% Distance-based outlier filtering
p.addParameter('filter_inliers', true);
p.addParameter('filter_method', 'gm'); % 'gm' or 'kmeans'
p.addParameter('filter_method_gridded', 'kmeans'); % 'gm' or 'kmeans'
p.addParameter('grid_aligned', {});
p.addParameter('gm_replicates', 5); % default = 5
p.addParameter('gm_clustering_method', 'largest'); % 'std' or 'mean' or 'largest'
p.addParameter('kmeans_replicates', 5); % default = 5
p.addParameter('kmeans_clustering_method', 'largest'); % 'std' or 'mean' or 'largest'

% Angle-based filtering
p.addParameter('filter_angles', false);
p.addParameter('filter_angles_gridded', true);
p.addParameter('angle_tolerance', 15);

% Debugging and visualization
p.addParameter('verbosity', 0);
p.addParameter('show_region_stats', false);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
end