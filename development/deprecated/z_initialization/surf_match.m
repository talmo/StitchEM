function [matching_pts1, matching_pts2, scores] = surf_match(img1, img2, parameters)
%SURF_MATCH Returns matching points between two images.
%% Parameters
% Detection
params.surf.MetricThreshold = 1000; % default = 1000
params.surf.NumOctave = 3; % default = 3
params.surf.NumScaleLevels = 4; % default = 4
params.surf.SURFSize = 64; % default = 64

% Matching
params.NNR.Method = 'NearestNeighborRatio'; % default = 'NearestNeighborRatio'
params.NNR.Metric = 'SSD'; % default = 'SSD'
params.NNR.MatchThreshold = 1.0; % default = 1.0
params.NNR.MaxRatio = 0.6; % default = 0.6

if nargin > 2
    params = overwrite_defaults(params, parameters);
end

%% Detection and matching
% Get points
tic;
[pts1, desc1] = get_feats(img1, params);
[pts2, desc2] = get_feats(img2, params);
fprintf('Found %d and %d features. [%.2fs]\n', size(pts1, 1), size(pts2, 1), toc)

% Match using NNR
tic;
[match_indices, scores] = matchFeatures(desc1, desc2, ...
    'MatchThreshold', params.NNR.MatchThreshold, ...
    'Method', params.NNR.Method, ...
    'Metric', params.NNR.Metric, ...
    'MaxRatio', params.NNR.MaxRatio);

% Get the points corresponding to the matched features
matching_pts1 = pts1(match_indices(:, 1), :);
matching_pts2 = pts2(match_indices(:, 2), :);
fprintf('Found %d potentially matching features. [%.2fs]\n', size(matching_pts1, 1), toc)
end

function [points, descriptors] = get_feats(img, params)

% Find interest points
interest_points = detectSURFFeatures(img, ...
    'MetricThreshold', params.surf.MetricThreshold, ...
    'NumOctave', params.surf.NumOctave, ...
    'NumScaleLevels', params.surf.NumScaleLevels);

% Get descriptors from pixels around interest points
[descriptors, valid_points] = extractFeatures(img, ...
    interest_points, ...
    'SURFSize', params.surf.SURFSize);

% Save valid and adjusted points
points = valid_points(:).Location;

end