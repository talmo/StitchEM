function matches = match_features(ptsA, descA, ptsB, descB, parameters)
%MATCH_FEATURES Finds matches between two vectors of feature descriptors.
%   Uses nearest neighbor ratio matching to find putative matches between
%   the descriptors and then filters matches by their spatial distance.

%% Parameters
% Default parameters
params.NNR.Method = 'NearestNeighborRatio';
params.NNR.Metric = 'SSD';
params.NNR.MatchThreshold = 1.0;
params.NNR.MaxRatio = 0.7;
params.inlier.method = 'cluster'; % or 'cutoff' or 'none'
params.inlier.DistanceCutoff = 800;
params.inlier.GMClusters = 2;
params.inlier.GMReplicates = 5;

% Overwrite defaults with any parameters passed in
if nargin >= 5
    f = fieldnames(parameters); % fields
    for i = 1:length(f)
        sf = fieldnames(parameters.(f{i})); % subfields
        for e = 1:length(sf)
            params.(f{i}).(sf{e}) = parameters.(f{i}).(sf{e});
        end
    end
end

%% Match feature descriptors using nearest neighbor ratio
% Note: This function consumes a lot of memory!
[match_indices, scores] = matchFeatures(descA, descB, ...
    'MatchThreshold', params.NNR.MatchThreshold, ...
    'Method', params.NNR.Method, ...
    'Metric', params.NNR.Metric, ...
    'MaxRatio', params.NNR.MaxRatio);

% Get the points corresponding to the matched features
matched_ptsA = ptsA(match_indices(:, 1), :);
matched_ptsB = ptsB(match_indices(:, 2), :);

% Calculate the Euclidean distance between each pair of points
distances = match_distances(matched_ptsA, matched_ptsB);

% Use a hard cutoff for distance for inlier detection
if strcmp(params.inlier.method, 'cutoff')
    % Get the indices of matches with a distance lower than the cutoff
    inliersA = match_indices(distances <= params.inlier.DistanceCutoff, 1);
    inliersB = match_indices(distances <= params.inlier.DistanceCutoff, 2);

    % Concatenate indices to return pairs
    matches = [inliersA inliersB];

% Cluster matches by their distance using a mixture of Gaussian models
elseif strcmp(params.inlier.method, 'cluster')
    % Try to fit N Gaussians
    N = params.inlier.GMClusters;
    options = statset('Display','final');
    
    % Calculate fit of Gaussian models
    fit = gmdistribution.fit(distances, N, 'Replicates', params.inlier.GMReplicates);
    
    % Cluster based on calculated models
    clusters_idx = cluster(fit, distances);
    
    % Find cluster with lowest mean
    cluster_means = zeros(N, 1);
    for n = 1:N
        cluster_means(n) = mean(distances(clusters_idx == n));
        %fprintf('  Inlier cluster: %d, mean: %.2f\n', n, cluster_means(n))
    end
    [~, c] = min(cluster_means);
    
    % Inliers are the matches in the cluster with the lowest mean
    inlier_indices = (clusters_idx == c);
    matches = [match_indices(inlier_indices, 1) match_indices(inlier_indices, 2)];
    
% Don't do any inlier detection
else
    % Return without distance-based inlier detection
    matches = [match_indices(:, 1) match_indices(:, 2)];
end

end
