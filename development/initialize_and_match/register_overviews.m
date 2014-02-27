function [tform, tform_tile, tform_moving, tform_scale] = register_overviews(fixed_sec_num, moving_sec_num, parameters)
%REGISTER_OVERVIEWS Returns a transformation to register two section overviews.
% tform = Final rough alignment transform for the first tile in moving sec
% tform_tile = Registers resized tile to moving montage overview
% tform_moving = Registers moving montage overview to fixed
% tform_scale = Scales registered tile back to original resolution

%% Parameters
% Pre-processing
params.scale_ratio = 0.5;
params.crop_ratio = 0.5;

% Image filtering
params.median_filter_radius = 6; % default = 3

% Visualization
params.show_registrations = false;

% Tile registration
params.tile_scale_ratio = 0.05;
params.tile_to_register = 1;

% Overwrite defaults with any parameters passed in
if nargin > 2
    params = overwrite_defaults(params, parameters);
end

%% Load and process images
% Load overviews
fixed_unfiltered = load_sec(fixed_sec_num, params);
moving_unfiltered = load_sec(moving_sec_num, params);

% Apply smoothing filter
fixed = median_filter(fixed_unfiltered, params.median_filter_radius);
moving = median_filter(moving_unfiltered, params.median_filter_radius);

% Load and resize tile
tile = imresize(imshow_tile(moving_sec_num, params.tile_to_register, true), params.tile_scale_ratio);

%% Registrations
% Register tile to moving overview
fprintf('== Registering tile %d in section %d to its montage overview.\n', params.tile_to_register, moving_sec_num);
tform_tile = surf_register(moving_unfiltered, tile, params);

% Register moving overview to fixed overview
fprintf('== Registering montage overviews between sections %d and %d.\n', fixed_sec_num, moving_sec_num);
tform_moving = surf_register(fixed, moving, params);

%% Compose combined transform
% Calculate the scaling transform to get back to original tile resolution
tile_scale_ratio = 1 / (params.tile_scale_ratio * estimate_tform_params(tform_tile));
tform_scale = affine2d([tile_scale_ratio 0 0; 0 tile_scale_ratio 0; 0 0 1]);

% Combine the transforms
tform = affine2d(tform_tile.T * tform_moving.T * tform_scale.T);

disp('Composed rough alignment transform from registrations.')

%% Visualize registration results
if params.show_registrations
    % Register tile to moving
    [tile_registered, tile_registered_spatial_ref] = imwarp(tile, tform_tile);
    
    % Register moving to fixed
    [moving_registered, moving_registered_spatial_ref] = imwarp(moving_unfiltered, tform_moving);
    
    % Register tile to moving that was registered to fixed
    [tile_registered_to_fixed, tile_registered_to_fixed_spatial_ref] = imwarp(tile, affine2d(tform_tile.T * tform_moving.T));
    
    % Display merges
    figure
    imshowpair(moving_unfiltered, imref2d(size(moving_unfiltered)), tile_registered, tile_registered_spatial_ref);
    title(sprintf('Tile (%d) registered to moving (sec %d)', params.tile_to_register, moving_sec_num))
    
    figure
    imshowpair(fixed_unfiltered, imref2d(size(fixed_unfiltered)), moving_registered, moving_registered_spatial_ref);
    title(sprintf('Moving (sec %d) registered to fixed (sec %d)', moving_sec_num, fixed_sec_num))
        
    %figure
    %imshowpair(fixed_unfiltered, imref2d(size(fixed_unfiltered)), tile_registered_to_fixed, tile_registered_to_fixed_spatial_ref);
    %title(sprintf('Tile (%d) registered to fixed (sec %d)', params.tile_to_register, fixed_sec_num))
    
    figure
    imshowpair(moving_registered, moving_registered_spatial_ref, tile_registered_to_fixed, tile_registered_to_fixed_spatial_ref);
    title(sprintf('Tile (%d) and moving (sec %d) registered to fixed', params.tile_to_register, fixed_sec_num))

    % Merge all
    [fixed_moving, fixed_moving_spatial_ref] = imfuse(fixed_unfiltered, imref2d(size(fixed_unfiltered)), moving_registered, moving_registered_spatial_ref, 'ColorChannels', [1 2 0]);
    [fixed_moving_tile, fixed_moving_tile_spatial_ref] = imfuse(fixed_moving, fixed_moving_spatial_ref, tile_registered_to_fixed, tile_registered_to_fixed_spatial_ref, 'ColorChannels', [1 1 2]);
    figure
    imshow(fixed_moving_tile, fixed_moving_tile_spatial_ref)
    title('Combined registration')
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