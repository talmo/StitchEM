function tform = surf_register(fixed_img, moving_img, parameters)
%SURF_REGISTER Estimates a transformation to register two images.
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

% Transform estimation
params.MSAC.transformType = 'similarity'; % default = 'similarity'
params.MSAC.MaxNumTrials = 500; % default = 1000
params.MSAC.Confidence = 99; % default = 99
params.MSAC.MaxDistance = 1.5; % default = 1.5

if nargin > 2
    params = overwrite_defaults(params, parameters);
end

%% Detection and matching
% Get points
tic;
[fixed_pts, fixed_desc] = get_feats(fixed_img, params);
[moving_pts, moving_desc] = get_feats(moving_img, params);
fprintf('Found %d and %d features. [%.2fs]\n', size(fixed_pts, 1), size(moving_pts, 1), toc)

% Match using NNR
tic;
[match_indices, scores] = matchFeatures(fixed_desc, moving_desc, ...
    'MatchThreshold', params.NNR.MatchThreshold, ...
    'Method', params.NNR.Method, ...
    'Metric', params.NNR.Metric, ...
    'MaxRatio', params.NNR.MaxRatio);

% Get the points corresponding to the matched features
fixed_matching_pts = fixed_pts(match_indices(:, 1), :);
moving_matching_pts = moving_pts(match_indices(:, 2), :);
fprintf('Found %d potentially matching features. [%.2fs]\n', size(fixed_matching_pts, 1), toc)

%% Transform estimation
% Find inliers and calculate transform
tic;
[tform, moving_inliers, fixed_inliers] = estimateGeometricTransform(moving_matching_pts, fixed_matching_pts, ...
    params.MSAC.transformType, 'MaxNumTrials', params.MSAC.MaxNumTrials, 'Confidence', params.MSAC.Confidence, 'MaxDistance', params.MSAC.MaxDistance);
fprintf('Found %d inliers within matches and estimated registration transform. [%.2fs]\n', size(fixed_inliers, 1), toc)

% Calculate error
mean_registration_error = calculate_registration_error(fixed_inliers, moving_inliers, tform);
fprintf('Registration error: %.2fpx\n', mean_registration_error);

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

% Save valid points
points = valid_points(:).Location;

end