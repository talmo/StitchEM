%% Parameters
% Detection
params.surf.MetricThreshold = 500; % default = 1000
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

%% Section 87
% Load montage overview
sec87 = imshow_montage(87, true);

% Resize
scale_ratio = 0.5;
fixed_unfiltered = imresize(sec87, scale_ratio);

% Crop to center
crop_ratio = 0.5;
fixed_unfiltered = imcrop(fixed_unfiltered, [size(fixed_unfiltered, 2) * (crop_ratio / 2), size(fixed_unfiltered, 1) * (crop_ratio / 2), size(fixed_unfiltered, 2) * crop_ratio, size(fixed_unfiltered, 1) * crop_ratio]);

% Sharpen filter
fixed_filtered = imsharpen(fixed_unfiltered);
fixed_filtered = deconvwnr(fixed_filtered, fspecial('gaussian', 3, 0.5));
median_filter_radius = 3;
fixed_filtered = medfilt2(fixed_filtered, [median_filter_radius median_filter_radius]);

% Load another section
sec88 = imshow_montage(88, true);
moving_unfiltered = imresize(sec88, scale_ratio);
moving_unfiltered = imcrop(moving_unfiltered, [size(moving_unfiltered, 2) * (crop_ratio / 2), size(moving_unfiltered, 1) * (crop_ratio / 2), size(moving_unfiltered, 2) * crop_ratio, size(moving_unfiltered, 1) * crop_ratio]);
median_filter_radius = 1;
moving_filtered = medfilt2(moving_unfiltered, [median_filter_radius median_filter_radius]);

imshowpair(fixed_filtered, moving_filtered, 'montage');

% Find matches
fixed = fixed_filtered;
moving = moving_filtered;
[fixed_matches, moving_matches] = surf_match(fixed, moving, params);

% Find inliers and calculate transform
tic;
[tform, moving_inliers, fixed_inliers] = estimateGeometricTransform(moving_matches, fixed_matches, ...
    params.MSAC.transformType, 'MaxNumTrials', params.MSAC.MaxNumTrials, 'Confidence', params.MSAC.Confidence, 'MaxDistance', params.MSAC.MaxDistance);
fprintf('Calculated transform and filtered down to %d inliers. [%.2fs]\n', size(fixed_inliers, 1), toc)


% Apply transform and get spatial reference
[registered, registered_spatial_ref] = imwarp(moving_unfiltered, tform);

% Get spatial reference for fixed image
fixed_spatial_ref = imref2d(size(fixed_unfiltered));

% Get spatially referenced images padded with zeros
[fixed_padded, registered_padded] = calculateOverlayImages(fixed_unfiltered, fixed_spatial_ref, registered, registered_spatial_ref);

% Merge into one image
merge = imfuse(fixed_padded, registered_padded, 'falsecolor');
figure, imshow(merge)
title('Registration result')

% Apply transform to points
transformed_moving_inliers = tform.transformPointsForward(moving_inliers);
registered_distances = calculate_match_distances(fixed_inliers, transformed_moving_inliers);
mean_registered_distances = mean(registered_distances);
fprintf('Average distance after registration: %.2fpx\n', mean_registered_distances);

% Calculate detected angle and translation
[theta, tx, ty, scale] = analyze_tform(tform);
fprintf('Transform Angle: %f, Translation: [%f, %f], Scale: %f\n', theta, tx, ty, scale)

