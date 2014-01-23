% This script compares different methods of feature matching across
% sections. Primarily, we're trying to see if resizing the image ahead of
% time will serve to increase cross-section matching accuracy.

%% Load things
% Load sections
secA = initialize_section('/data/home/talmo/EMdata/W002/S2-W002_Sec100_Montage');
secB = initialize_section('/data/home/talmo/EMdata/W002/S2-W002_Sec102_Montage');

% Load images
tic;
tileA = imread(secA.tiles(1).path);
tileB = imread(secB.tiles(1).path);
fprintf('Loaded images in %.2fs.\n', toc)

%% Resize
tic;
tileA_small = imresize(tileA, 0.25);
tileB_small = imresize(tileB, 0.25);
fprintf('Resized images in %.2fs.\n', toc)

%% Find features
params = struct();
params.detect.MetricThreshold = 10000; % Default = 5000
params.detect.NumOctave = 3;
params.detect.NumScaleLevels = 4;

params_small.detect.MetricThreshold = 5000;
params_small.detect.NumOctave = 3;
params_small.detect.NumScaleLevels = 4;

tic;
[ptsA, descA] = find_features(tileA, 'surf', size(tileA), params);
[ptsB, descB] = find_features(tileB, 'surf', size(tileB), params);
fprintf('Found %d and %d features in full images in %.2fs.\n', size(ptsA, 1), size(ptsB, 1), toc)

tic;
[ptsA_small, descA_small] = find_features(tileA_small, 'surf', size(tileA_small), params_small);
[ptsB_small, descB_small] = find_features(tileB_small, 'surf', size(tileA_small), params_small);
fprintf('Found %d and %d features in small images in %.2fs.\n', size(ptsA_small, 1), size(ptsB_small, 1), toc)

%% Match features
params = struct();
params.NNR.MatchThreshold = 0.90;
params.NNR.MaxRatio = 0.7;
params.inlier.method = 'cluster';
params.inlier.DistanceCutoff = 800;
params.inlier.GMClusters = 2;
params.inlier.GMReplicates = 5;

params_small.NNR.MatchThreshold = 0.90;
params_small.NNR.MaxRatio = 0.7;
params_small.inlier.method = 'cluster';
params_small.inlier.DistanceCutoff = 200;
params_small.inlier.GMClusters = 2;
params_small.inlier.GMReplicates = 5;

tic;
matches_full = match_features(ptsA, descA, ptsB, descB, params);
fprintf('Found %d matches in full images in %.2fs.\n', size(matches_full, 1), toc)

tic;
matches_small = match_features(ptsA_small, descA_small, ptsB_small, descB_small, params_small);
fprintf('Found %d matches in small images in %.2fs.\n', size(matches_small, 1), toc)

%% Plot matches
fprintf('Full images:\n')
matching_pointsA = ptsA(matches_full(:, 1), :);
matching_pointsB = ptsB(matches_full(:, 2), :);
dists_full = match_distances(matching_pointsA, matching_pointsB);
plot_matches(matching_pointsA, matching_pointsB, 8000);
set(gcf, 'Position', [1965, 500, 560, 420])
title('Full images')

fprintf('Small images:\n')
matching_pointsA_small = ptsA_small(matches_small(:, 1), :);
matching_pointsB_small = ptsB_small(matches_small(:, 2), :);
dists_small = match_distances(matching_pointsA_small, matching_pointsB_small);
plot_matches(matching_pointsA_small, matching_pointsB_small, 2000);
set(gcf, 'Position', [2535, 500, 560, 420])
title('Small images')

%% Fit Gaussians to distances

% N = up to which number of parameters to try to fit to
N = 2;
fits = cell(N, 1);
sorted_dists = sort(dists_small);
fprintf('AIC for Gaussian Mixture Models:\n')
figure
for n = 1:N
    % Calculate fit
    fits{n} = gmdistribution.fit(sorted_dists, n);
    
    % Output AIC
    fprintf('  N = %d: %.2f\n', n, fits{n}.AIC)
    
    % Cluster data based on fit
    idx = cluster(fits{n}, sorted_dists);
    
    % Plot clusters
    X = 1 : numel(sorted_dists);
    colors = ['b', 'r', 'g', 'b', 'c', 'm', 'y', 'k', 'w'];
    subplot(N, 1, n)
    title(sprintf('N = %d', n))
    hold on
    for i = 1:n
        cluster_idx = (idx == i);
        bar(X(cluster_idx), sorted_dists(cluster_idx), colors(i))
    end
    hold off
    
end

%% Test how often the Gaussian fitting fails
fprintf('Detecting inliers by clustering with Gaussian Mixtures...\n')
trials = 250;

params = struct();
params.NNR.MatchThreshold = 0.90;
params.NNR.MaxRatio = 0.7;
params.inlier.method = 'cluster';
params.inlier.GMClusters = 2;
params.inlier.GMReplicates = 1;

means = zeros(trials, 1);
num_matches = zeros(trials, 1);

tic;
for i = 1:trials
    % Match features using the GM clustering
    matches = match_features(ptsA_small, descA_small, ptsB_small, descB_small, params);
    
    % Get the actual points
    matching_pointsA = ptsA_small(matches(:, 1), :);
    matching_pointsB = ptsB_small(matches(:, 2), :);
    
    % Calculate the distances between the matching points
    distances = match_distances(matching_pointsA, matching_pointsB);
    
    % Save trial data
    means(i) = mean(distances);
    num_matches(i) = size(matches, 1);
end
fprintf('Finished %d trials of inlier detection in %.2fs.\n', trials, toc);

% Calculate success rate
fprintf('Number of Matches:\n')
unique_num_matches = unique(num_matches);
occurrences = zeros(numel(unique_num_matches), 1);
for n = 1:numel(unique_num_matches)
    occurrences(n) = sum(num_matches == unique_num_matches(n));
    fprintf('  %d matches: %d (%.2f%%)\n', unique_num_matches(n), occurrences(n), occurrences(n) / trials * 100)
end
fprintf('Success rate: %.2f%%\n', max(occurrences) / trials * 100);

% Plot results
if false
    figure
    subplot(1, 2, 1)
    bar(means), title('Means of distances')
    subplot(1, 2, 2)
    bar(num_matches), title('Number of matches detected')
end
