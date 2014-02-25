%% Parameters
params.display_montage = false;
params.display_matches = false;
params.display_merge = false;
params.median_filter = true;
params.median_filter_radius = 6;
params.MSAC.transformType = 'similarity';
params.MSAC.MaxNumTrials = 500;

%% Register tile to section montage
sec_num = 1;
tile_num = 3;
tile_scale_factor = 0.05;

% Load tile and resize
full_tile = imshow_tile(sec_num + 1, tile_num, true);
tile = imresize(full_tile, tile_scale_factor);

% Register section montage and get the resized montage overview image
[~, fixed_sec, sec_montage, sec_tform] = quick_registration(sec_num, sec_num + 1, params);

% Find matches between montage overview and tile
[sec_matches, tile_matches] = surf_match(sec_montage, tile);

% Find inliers and calculate transform
[tile_tform, tile_inliers, sec_inliers] = estimateGeometricTransform(tile_matches, sec_matches, params.MSAC.transformType, 'MaxNumTrials', params.MSAC.MaxNumTrials);
fprintf('Found %d inliers within matches.\n', size(tile_inliers, 1))

% Apply transform to points and calculate distance
transformed_tile_inliers = tile_tform.transformPointsForward(tile_inliers);
registered_distances = calculate_match_distances(sec_inliers, transformed_tile_inliers);
mean_registered_distances = mean(registered_distances);
fprintf('Average distance after registration: %.2fpx\n', mean_registered_distances);

% Analyze transform to get the scaling factor
[~, ~, ~, tile_scale] = analyze_tform(tile_tform);

% Calculate final scaling factor
final_scale_factor = tile_scale_factor * tile_scale;
fprintf('Final Scaling Factor: %f\n', final_scale_factor)

% Apply the transform to the tile
[registered_tile, registered_spatial_ref] = imwarp(tile, tile_tform);

% Visualize the registration of tile to own section montage
sec_spatial_ref = imref2d(size(sec_montage));
imshowpair(sec_montage, sec_spatial_ref, registered_tile, registered_spatial_ref)
title('')
%% Test detected parameters for transformation
% Compute new transform based on cross-section montage registration
[theta, tx, ty, ~] = analyze_tform(sec_tform);
rotation_T = [cosd(theta) -sind(theta) 0; sind(theta) cosd(theta) 0; 0 0 1];
translation_T = [1 0 0; 0 1 0; (tx / final_scale_factor) (ty / final_scale_factor) 1];
full_tform = affine2d(rotation_T * translation_T);

% Apply transform to full tile
[full_tile_registered, full_tile_registered_spatial_ref] = imwarp(full_tile, full_tform);

% Resize the tile down since padding it at full resolution blows up memory
downscale_factor = 0.1;
full_tile_registered_downscaled = imresize(full_tile_registered, downscale_factor);

% Scale down the spatial registration of the tile to the section montage overview resolution
xWorldLimits = registered_spatial_ref.XWorldLimits;
yWorldLimits = registered_spatial_ref.YWorldLimits;
full_tile_registered_downscaled_spatial_ref = imref2d(size(full_tile_registered_downscaled), xWorldLimits, yWorldLimits);

% Visualize the registration
figure
imshowpair(sec_montage, imref2d(size(sec_montage)), full_tile_registered_downscaled, full_tile_registered_downscaled_spatial_ref)
title('Full resolution tile registered to own section')
figure
imshowpair(fixed_sec, imref2d(size(fixed_sec)), full_tile_registered_downscaled, full_tile_registered_downscaled_spatial_ref)
title('Full resolution tile registered to adjacent section')