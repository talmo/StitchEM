function [merge, fixed_padded, registered_padded, tform, mean_registered_distances] = feature_based_registration(sec_num_fixed, sec_num_moving, parameters)
%% Parameters
% Pre-processing
params.scale_ratio = 0.5;
params.crop_ratio = 0.5;

% Pre-filtering
params.highlow_filter = false;
params.high_threshold = 210;
params.low_threshold = 180;
params.median_filter = false;
params.median_filter_radius = 3; % default = 3

% Testing
params.display_montage = true;
params.display_matches = true;
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

% Overwrite defaults with any parameters passed in
if nargin > 2
    params = overwrite_defaults(params, parameters);
end


%% Load stage stitched images

fixed_unfiltered = imread(sprintf('/data/home/talmo/EMdata/W002/S2-W002_Sec%d_Montage/MontageOverviewImage_S2-W002_sec%d.tif', sec_num_fixed, sec_num_fixed));
fixed_unfiltered = pre_process(fixed_unfiltered, params.scale_ratio, params.crop_ratio);
fixed = pre_filter(fixed_unfiltered, params.highlow_filter, params.high_threshold, params.low_threshold, params.median_filter, params.median_filter_radius);

moving_unfiltered = imread(sprintf('/data/home/talmo/EMdata/W002/S2-W002_Sec%d_Montage/MontageOverviewImage_S2-W002_sec%d.tif', sec_num_moving, sec_num_moving));
moving_unfiltered = pre_process(moving_unfiltered, params.scale_ratio, params.crop_ratio);
moving = pre_filter(moving_unfiltered, params.highlow_filter, params.high_threshold, params.low_threshold, params.median_filter, params.median_filter_radius);

%% Show montage (side-by-side)
if params.display_montage
    figure, imshowpair(fixed, moving, 'montage')
end

%% Detect matching features
% Get matching points
[fixed_matches, moving_matches] = surf_match(fixed, moving, params);

% Find inliers and calculate transform
tic;
[tform, moving_inliers, fixed_inliers] = estimateGeometricTransform(moving_matches, fixed_matches, ...
    params.MSAC.transformType, 'MaxNumTrials', params.MSAC.MaxNumTrials, 'Confidence', params.MSAC.Confidence, 'MaxDistance', params.MSAC.MaxDistance);
fprintf('Calculated transform and filtered down to %d inliers. [%.2fs]\n', size(fixed_inliers, 1), toc)

% Display matches and histograms
if params.display_matches
    % Display matches before filtering
    figure, subplot(2, 2, 1)
    showMatchedFeatures(fixed, moving, fixed_matches, moving_matches);
    title('Matched features, including outliers')

    % Display match distance histogram
    distances = calculate_match_distances(fixed_matches, moving_matches);
    subplot(2, 2, 2)
    hist(distances)
    title('Match distances')
    
    % Display matches after filtering
    subplot(2, 2, 3)
    showMatchedFeatures(fixed, moving, fixed_inliers, moving_inliers);
    title('Matched features, only inliers')

    % Display inlier distance histogram
    inlier_distances = calculate_match_distances(fixed_inliers, moving_inliers);
    subplot(2, 2, 4)
    hist(inlier_distances)
    title('Inlier distances')
    
    fprintf('Average inlier distance: %.2fpx\n', mean(inlier_distances))
end

transformed_moving_inliers = tform.transformPointsForward(moving_inliers);
registered_distances = calculate_match_distances(fixed_inliers, transformed_moving_inliers);
mean_registered_distances = mean(registered_distances);
fprintf('Average distance after registration: %.2fpx\n', mean_registered_distances);

%% Apply transform and display result
% Apply transform and get spatial reference
[registered, registered_spatial_ref] = imwarp(moving_unfiltered, tform);

% Get spatial reference for fixed image
fixed_spatial_ref = imref2d(size(fixed_unfiltered));

% Get spatially referenced images padded with zeros
[fixed_padded, registered_padded] = calculateOverlayImages(fixed_unfiltered, fixed_spatial_ref, registered, registered_spatial_ref);

merge = imfuse(fixed_padded, registered_padded, 'falsecolor');
if params.display_merge
    figure, imshow(merge)
    title('Registration result')
end

%% Quantify registration results
% Get individual images
%[fixed_padded, registered_padded, fixed_mask, registered_mask, merge_spatial_ref] = calculateOverlayImages(fixed, fixed_spatial_ref, registered, registered_spatial_ref);
%fprintf('Corr = %f -> %f\n', corr2(fixed, moving), corr2(fixed_padded, registered_padded))

% calculate correct "masks" by applying transform to a logical all "white"
% mask of the size of moving and the size of fixed and then putting them
% through calculateOverlayImages

% Get the intersection of these masks and extract those pixels from
% fixed_padded and registered_padded

% Do correlation on those extracted pixels

end

function I = pre_process(I, scale_ratio, crop_ratio)
    % Resize
    I = imresize(I, scale_ratio);
    
    % Crop to center
    I = imcrop(I, [size(I, 2) * (crop_ratio / 2), size(I, 1) * (crop_ratio / 2), size(I, 2) * crop_ratio, size(I, 1) * crop_ratio]);
end

function I = pre_filter(I, highlow_filter, high_threshold, low_threshold, median_filter, median_filter_radius)
    % High and low-pass filter
    if highlow_filter
        im = I;
        im(I > high_threshold) = 0;
        im(I < low_threshold) = 0;
        I = im;
    end
    
    % Median filter
    if median_filter
        I = medfilt2(I, [median_filter_radius median_filter_radius]);
    end
end