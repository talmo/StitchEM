function matches = match_features(ptsA, descA, ptsB, descB)
%MATCH_FEATURES Finds matches between two vectors of feature descriptors.
%   Uses nearest neighbor ratio matching to find putative matches between
%   the descriptors and then filters matches by their spatial distance.

%% Parameters
NNR.Method = 'NearestNeighborRatio';
NNR.MatchThreshold = 1000;
NNR.Metric = 'SSD';
NNR.MaxRatio = 0.7;
inlier.DistanceCutoff = 40;

%% Match feature descriptors using nearest neighbor ratio
% Note: This function consumes a lot of memory!
[match_indices, scores] = matchFeatures(descA, descB, ...
    'MatchThreshold', NNR.MatchThreshold, 'Method', NNR.Method, ...
    'Metric', NNR.Metric, 'MaxRatio', NNR.MaxRatio);

% Get the points corresponding to the matched features
pairsA = ptsA(match_indices(:, 1), :);
pairsB = ptsB(match_indices(:, 2), :);

% Calculate the Euclidean distance between each pair of points
distances = sqrt(sum((pairsA - pairsB) .^2, 2));

% Get the indices of matches with a distance lower than the cutoff
inliersA = match_indices(distances <= inlier.DistanceCutoff, 1);
inliersB = match_indices(distances <= inlier.DistanceCutoff, 2);

% Concatenate indices to return pairs
matches = [inliersA inliersB];

end
