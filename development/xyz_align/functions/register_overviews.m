function [tform_moving, varargout] = register_overviews(moving_sec, fixed_sec, varargin)
%REGISTER_OVERVIEWS Registers the moving section overview montage to the fixed one.

registration_time = tic;

%% Register overviews
% Parse inputs
params = parse_input(varargin{:});
tform_fixed = fixed_sec.overview_tform;

if params.verbosity > 0
    fprintf('== Registering overview of section %d to section %d.\n', moving_sec.num, fixed_sec.num)
end

% Preprocess the images (resize, crop, filter)
[fixed_unfiltered, fixed_filtered] = pre_process(fixed_sec.img.overview, params);
[moving_unfiltered, moving_filtered] = pre_process(moving_sec.img.overview, params);

% Register overviews
[tform_moving, ~, ~, mean_registration_error] = surf_register(fixed_filtered, moving_filtered, 'MSAC_MaxNumTrials', 1000);

% Adjust transform for initial transforms
tform_moving = affine2d(tform_fixed.T * tform_moving.T);

if params.verbosity > 0
    fprintf('Done registering overviews. Mean error = %.2fpx [%.2fs]\n', mean_registration_error, toc(registration_time))
end

%% Visualize results
if params.show_registration
    % Apply the transform to fixed if needed
    if any(any(tform_fixed.T ~= eye(3)))
        [fixed, fixed_spatial_ref] = imwarp(fixed_unfiltered, tform_fixed);
    else
        fixed = fixed_unfiltered;
        fixed_spatial_ref = imref2d(size(fixed));
    end
    
    % Apply the transform to moving
    [moving, moving_spatial_ref] = imwarp(moving_unfiltered, tform_moving);
    
    % Merge the overviews and display result
    [merge, merge_spatial_ref] = imfuse(fixed, fixed_spatial_ref, moving, moving_spatial_ref);
    figure
    imshow(merge, merge_spatial_ref);
    
    % Return the visualization
    varargout = {merge, merge_spatial_ref, fixed, fixed_spatial_ref, moving, moving_spatial_ref};
end

end

function [unfiltered, filtered] = pre_process(im, params)
% Resize
if params.overview_prescale ~= params.overview_scale
    im = imresize(im, (1 / params.overview_prescale) * params.overview_scale);
end

% Crop to center
unfiltered = imcrop(im, [size(im, 2) * (params.crop_ratio / 2), size(im, 1) * (params.crop_ratio / 2), size(im, 2) * params.crop_ratio, size(im, 1) * params.crop_ratio]);

% Apply median filter
if params.median_filter_radius > 0
    filtered = medfilt2(unfiltered, [params.median_filter_radius params.median_filter_radius]);
else
    filtered = unfiltered;
end

end

function params = parse_input(varargin)

% Create inputParser instance
p = inputParser;

% Pre-processing
p.addParameter('overview_scale', 0.78);
p.addParameter('overview_prescale', 0.78);
p.addParameter('crop_ratio', 0.5);

% Image filtering
p.addParameter('median_filter_radius', 6);

% Verbosity
p.addParameter('verbosity', 1);

% Visualization
p.addParameter('show_registration', false);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
end
