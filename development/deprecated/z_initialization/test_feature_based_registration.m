%%
test_data = {};
merges = {};

%%
% Which sections
fixed_sec = 1;
moving_sec = 2;

% Pre-processing
params.scale_ratio = 0.5;
params.crop_ratio = 0.5;

% Pre-filtering
params.highlow_filter = false;
params.high_threshold = 225;
params.low_threshold = 150;
params.median_filter = true;
params.median_filter_radius = 6; % default = 3

% Testing
params.display_montage = false;
params.display_matches = false;
params.display_merge = true;

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
%%
tic;
[merge, fixed_padded, registered_padded, tform, mean_registered_distances] = feature_based_registration(fixed_sec, moving_sec, params);
toc
% Calculate detected angle and translation
[theta, tx, ty, scale] = analyze_tform(tform);
fprintf('Transform Angle: %f, Translation: [%f, %f], Scale: %f\n', theta, tx, ty, scale)
%%
% Save results
test_data{end + 1} = {[fixed_sec, moving_sec], params, tform, mean_registered_distances, theta, [tx, ty]};
merges{end+1} = merge;



