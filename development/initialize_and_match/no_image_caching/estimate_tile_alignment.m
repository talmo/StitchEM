function [tform, tform_composition] = estimate_tile_alignment(fixed_sec_num, moving_sec_num, varargin)
%ESTIMATE_TILE_ALIGNMENT Returns a transformation to register two section overviews.
% tform = Final rough alignment transform for the tile in moving section
%
% tform_composition contains the following transforms:
% tform_prescale = Resizes the tile image down to a working resolution for feature detection
% tform_tile = Registers resized tile to moving montage overview
% tform_moving = Registers moving montage overview to fixed
% tform_rescale = Scales registered tile back to original resolution

%% Parameters
% Defaults
tile_num = 1;
tform_moving = affine2d();
montages_preregistered = false;
parameters = struct();

% Hackish processing of varargin
if ~isempty(varargin)
    for i = 1:length(varargin)
        if isnumeric(varargin{i}) % tile_num
            tile_num = varargin{i};
        elseif isa(varargin{i}, 'affine2d') % tform_moving
            montages_preregistered = true;
            tform_moving = varargin{i};
        elseif isstruct(varargin{i}) % parameters
            parameters = varargin{i};
        end
    end
end

%% Parameters structure defaults
% Pre-processing
params.scale_ratio = 0.5;
params.crop_ratio = 0.5;

% Image filtering
params.median_filter_radius = 6; % default = 3

% Tile registration
params.tile_scale_ratio = 0.05;

% Visualization and debugging
params.show_scaling = false;
params.show_registrations = false;
params.show_merge = false;

% Overwrite defaults with any parameters passed in
params = overwrite_defaults(params, parameters);

%% Register the tile to its section overview
tic;
% Load and resize tile
tile = imresize(imshow_tile(moving_sec_num, tile_num, true), params.tile_scale_ratio);

% Load moving montage overview
moving = load_sec(moving_sec_num, params);

% Note: This is also resizes the image, but is slower and doesn't have bicubic interpolation.
%tile = imwarp(imshow_tile(moving_sec_num, tile_num, true), scale_tform(params.tile_scale_ratio));

fprintf('== Loaded tile and montage images. [%.2fs]\n', toc);

% Register tile to moving overview
fprintf('== Registering tile %d in section %d to its montage overview.\n', tile_num, moving_sec_num);
tform_tile = surf_register(moving, tile, params);


%% Register the montage overviews
% If we don't already have the moving -> fixed registration transform
if ~montages_preregistered
    tic;
    % Load fixed montage overview
    fixed = load_sec(fixed_sec_num, params);

    % Apply smoothing filter
    moving_filtered = median_filter(moving, params.median_filter_radius);
    fixed_filtered = median_filter(fixed, params.median_filter_radius);
    fprintf('== Loaded and filtered montage images. [%.2fs]\n', toc);
    
    % Register moving overview to fixed overview
    fprintf('== Registering montage overviews between sections %d and %d.\n', fixed_sec_num, moving_sec_num);
    tform_moving = surf_register(fixed_filtered, moving_filtered, params);
    
end

%% Compose combined transform
% We scale down the tile initially using imresize since it's faster, but
% it's equivalent to applying this transform:
tform_prescale = scale_tform(params.tile_scale_ratio);

% We want to do undo that scaling, as well as the scaling done to register
% the tile to the montage overview
tform_rescale = scale_tform(1 / (params.tile_scale_ratio * estimate_tform_params(tform_tile)));

% Combine the transforms to do the following operations in this order:
% Prescale -> Register to moving -> Register to fixed -> Rescale
tform = affine2d(tform_prescale.T * tform_tile.T * tform_moving.T * tform_rescale.T);

% Return the individual transforms too
tform_composition.prescale = tform_prescale;
tform_composition.tile = tform_tile;
tform_composition.moving = tform_moving;
tform_composition.rescale = tform_rescale;

% Show the scaling component at each step
if params.show_scaling
    fprintf('\nparams.tile_scale_ratio = %f\n', params.tile_scale_ratio)
    fprintf('1 / (params.tile_scale_ratio * estimate_tform_params(tform_tile)) = %f\n\n', 1 / (params.tile_scale_ratio * estimate_tform_params(tform_tile)))

    fprintf('1. tform_prescale scale = %f\n', estimate_tform_params(tform_prescale))
    fprintf('2. tform_tile scale = %f\n', estimate_tform_params(tform_tile))
    fprintf('3. tform_moving scale = %f\n', estimate_tform_params(tform_moving))
    fprintf('4. tform_rescale scale = %f\n', estimate_tform_params(tform_rescale))
    fprintf('== tform scale = %f\n', estimate_tform_params(tform))
end

fprintf('Estimated rough alignment for section %d -> tile %d.\n', moving_sec_num, tile_num)

%% Visualize registration results
if params.show_merge || params.show_registrations
    % Load the fixed section overview if it wasn't loaded yet
    if ~exist('fixed', 'var')
        fixed = load_sec(fixed_sec_num, params);
    end
    
    % Register tile to moving that was registered to fixed
    [tile_registered_to_fixed, tile_registered_to_fixed_spatial_ref] = imwarp(tile, affine2d(tform_tile.T * tform_moving.T));
    
    % Register moving to fixed
    [moving_registered, moving_registered_spatial_ref] = imwarp(moving, tform_moving);
end

if params.show_registrations
    % Register tile to moving
    [tile_registered, tile_registered_spatial_ref] = imwarp(tile, tform_tile);
    
    % Display merges
    figure
    imshowpair(moving, imref2d(size(moving)), tile_registered, tile_registered_spatial_ref);
    title(sprintf('Tile (%d) registered to moving (sec %d)', tile_num, moving_sec_num))
    
    figure
    imshowpair(fixed, imref2d(size(fixed)), moving_registered, moving_registered_spatial_ref);
    title(sprintf('Moving (sec %d) registered to fixed (sec %d)', moving_sec_num, fixed_sec_num))
    
    %figure
    %imshowpair(fixed, imref2d(size(fixed)), tile_registered_to_fixed, tile_registered_to_fixed_spatial_ref);
    %title(sprintf('Tile (%d) registered to fixed (sec %d)', tile_num, fixed_sec_num))
    
    figure
    imshowpair(moving_registered, moving_registered_spatial_ref, tile_registered_to_fixed, tile_registered_to_fixed_spatial_ref);
    title(sprintf('Tile (%d) and moving (sec %d) registered to fixed', tile_num, fixed_sec_num))
end

if params.show_merge
    [fixed_moving, fixed_moving_spatial_ref] = imfuse(fixed, imref2d(size(fixed)), moving_registered, moving_registered_spatial_ref, 'ColorChannels', [1 2 0]);
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
