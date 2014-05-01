function features = detect_tile_features(sec_num, tile_num, parameters)
%DETECT_TILE_FEATURES Returns tile points and descriptors.
%% Parameters
% Pre-processing
params.tile_scale_ratio = 0.20;

% Detection
params.surf.MetricThreshold = 10000; % default = 1000
params.surf.NumOctave = 3; % default = 3
params.surf.NumScaleLevels = 4; % default = 4
params.surf.SURFSize = 64; % default = 64

if nargin > 3
    params = overwrite_defaults(params, parameters);
end

%% Load tile image
tic
tile = imresize(imshow_tile(sec_num, tile_num, true), params.tile_scale_ratio);

%% SURF feature detection
% Find interest points
interest_points = detectSURFFeatures(tile, ...
    'MetricThreshold', params.surf.MetricThreshold, ...
    'NumOctave', params.surf.NumOctave, ...
    'NumScaleLevels', params.surf.NumScaleLevels);

% Get descriptors from pixels around interest points
[descriptors, valid_points] = extractFeatures(tile, ...
    interest_points, 'SURFSize', params.surf.SURFSize);

% Save valid points
points = valid_points(:).Location;
num_features = size(points, 1);
fprintf('Detected %d features in section %d -> tile %d. [%.2fs]\n', num_features, sec_num, tile_num, toc);

%% Post-process SURF output
% Calculate transform to scale points up to original resolution
scale_tform = affine2d([(1 / params.tile_scale_ratio) 0 0; 0 (1 / params.tile_scale_ratio) 0; 0 0 1]);

% Apply them to the points to get the local coordinates in original resolution
local_points = scale_tform.transformPointsForward(points);

% Put everything in a table before returning
features = table(local_points, descriptors);

end

