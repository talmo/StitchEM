function [tform, montage_tform, tile_tform] = register_overviews(fixed_sec_num, moving_sec_num, parameters)
%REGISTER_OVERVIEWS Returns a transformation to register two section overviews.

%% Parameters
% Pre-processing
params.scale_ratio = 0.5;
params.crop_ratio = 0.5;

% Image filtering
params.median_filter_radius = 6; % default = 3

% Visualization
params.show_merge = false;
params.show_tile_merge = false;
params.show_tile_registration = true;

% Tile registration
params.tile_scale_ratio = 0.05;
params.tile_to_register = 1;

% Overwrite defaults with any parameters passed in
if nargin > 2
    params = overwrite_defaults(params, parameters);
end

%% Montage overview registration
fprintf('== Registering montage overviews between sections %d and %d.\n', fixed_sec_num, moving_sec_num);

% Load images
fixed = load_sec(fixed_sec_num, params);
moving = load_sec(moving_sec_num, params);

% Apply median filter
fixed_filtered = median_filter(fixed, params.median_filter_radius);
moving_filtered = median_filter(moving, params.median_filter_radius);

% Register the overview images
montage_tform = surf_register(fixed_filtered, moving_filtered, params);

%% Tile registration and transform scaling
fprintf('== Registering tile %d in section %d to its montage overview.\n', params.tile_to_register, moving_sec_num);

% Load and resize tile from moving section
tile = imresize(imshow_tile(moving_sec_num, params.tile_to_register, true), params.tile_scale_ratio);

% Register the tile to the moving section overview image
tile_tform = surf_register(moving, tile, params);

% Compose tile and section registration combined transform
combined_tform = affine2d(tile_tform.T * montage_tform.T);

% Calculate the final scale ratio for the tile relative to full resolution
tile_final_scale_ratio = params.tile_scale_ratio * estimate_tform_params(combined_tform);

% Build the scaling up transformation
scale_tform = [tile_final_scale_ratio 0 0; 0 tile_final_scale_ratio 0; 0 0 1];

% Compose combined transform scaled up to full resolution
tform = affine2d(combined_tform * scale_tform);

%% Visualize registration results
if params.show_merge
    % Apply the transform
    [registered, registered_spatial_ref] = imwarp(moving, montage_tform);
    
    % Display results
    figure
    imshowpair(fixed, imref2d(size(fixed)), registered, registered_spatial_ref);
    title(sprintf('Registered montage overviews for sections %d and %d', fixed_sec_num, moving_sec_num))
end

if params.show_tile_merge
    % Apply the transform
    [registered_tile, registered_tile_spatial_ref] = imwarp(tile, tile_tform);
    
    % Display results
    figure
    imshowpair(moving, imref2d(size(moving)), registered_tile, registered_tile_spatial_ref);
    title(sprintf('Tile %d in section %d registered to its section montage overview', params.tile_to_register, moving_sec_num))
end

if params.show_tile_registration
    % Apply the combined transform before scaling
    [registered_tile_combined, registered_tile_combined_spatial_ref] = imwarp(tile, combined_tform);
   
    % Display results
    figure
    imshowpair(registered, registered_spatial_ref, registered_tile_combined, registered_tile_combined_spatial_ref);
    title(sprintf('Tile %d in section %d registered to own section', params.tile_to_register, moving_sec_num))
    figure
    imshowpair(fixed, imref2d(size(fixed)), registered_tile_combined, registered_tile_combined_spatial_ref);
    title(sprintf('Tile %d in section %d registered to adjacent section', params.tile_to_register, moving_sec_num))
end

end

function im = load_sec(sec_num, params)
% Load full resolution montage overview image
im = imshow_montage(sec_num, true);

% Resize
im = imresize(im, params.scale_ratio);

% Crop to center
im = imcrop(im, [size(im, 2) * (params.crop_ratio / 2), size(im, 1) * (params.crop_ratio / 2), size(im, 2) * params.crop_ratio, size(im, 1) * params.crop_ratio]);


end

function im = median_filter(im, radius)
    % Apply median filter
    if radius > 0
        im = medfilt2(im, [radius radius]);
    end
end

function [scale, rotation, translation] = estimate_tform_params(tform)
% Translation
translation = [tform.T(3) tform.T(6)];

% Transform unit vector parallel to x-axis
u = [0 1];
v = [0 0];
[x, y] = transformPointsForward(tform, u, v);
dx = x(2) - x(1);
dy = y(2) - y(1);

% Calculate angle of rotation (counterclockwise)
rotation = -atan2d(dy, dx);

% Calculate scale
scale = sqrt(dx^2 + dy^2);
end