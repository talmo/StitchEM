function [tform_moving, varargout] = register_overviews(varargin)
%REGISTER_OVERVIEWS Registers the moving section overview montage to the fixed one.
% To register two section overviews:
%   tform_moving = register_overviews(fixed_img, moving_img);
%
% You can also specify an initial transformation to be applied to the 
% fixed overview that will be incorporated in the final transform:
%   tform_moving = register_overviews(fixed_img, tform_fixed, moving_img);
%
% Optional name-value pairs and their defaults:
%   scale_ratio = 0.5
%   crop_ratio = 0.5
%   median_filter_radius = 6
%   show_registration = false

%% Register overviews
% Parse inputs
[fixed_img, tform_fixed, moving_img, params] = parse_input(varargin{:});

% Preprocess the images (resize, crop, filter)
[fixed_unfiltered, fixed_filtered] = pre_process(fixed_img, params);
[moving_unfiltered, moving_filtered] = pre_process(moving_img, params);

% Register overviews
tform_moving = surf_register(fixed_filtered, moving_filtered, 'MSAC_MaxNumTrials', 1000);

% Adjust transform for initial transforms
tform_moving = affine2d(tform_fixed.T * tform_moving.T);

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
    imshow(merge, merge_spatial_ref);
    
    % Return the visualization
    varargout = {merge, merge_spatial_ref, fixed, fixed_spatial_ref, moving, moving_spatial_ref};
end

end

function [fixed_img, tform_fixed, moving_img, params] = parse_input(varargin)
% Initialize the image to being fixed by default
tform_fixed = affine2d();

% Check if any initial transform was passed in
tform_positions = find(cellfun(@(param) isa(param, 'affine2d'), varargin));

for pos = tform_positions
    if pos == 2
        tform_fixed = varargin{pos};
    else
        error('Invalid argument order. Make sure any initial transforms immediately follow its image in arguments.')
    end
end

% Get rid of any transforms from the argument list
varargin(tform_positions) = [];

% Create inputParser instance
p = inputParser;

% Images
p.addRequired('fixed_img');
p.addRequired('moving_img');

% Pre-processing
p.addParameter('scale_ratio', 0.5);
p.addParameter('crop_ratio', 0.5);

% Image filtering
p.addParameter('median_filter_radius', 6);

% Visualization
p.addParameter('show_registration', false);

% Validate and parse input
p.parse(varargin{:});
fixed_img = p.Results.fixed_img;
moving_img = p.Results.moving_img;
params = rmfield(p.Results, {'fixed_img', 'moving_img'});
end

function [unfiltered, filtered] = pre_process(im, params)
% Resize
im = imresize(im, params.scale_ratio);

% Crop to center
unfiltered = imcrop(im, [size(im, 2) * (params.crop_ratio / 2), size(im, 1) * (params.crop_ratio / 2), size(im, 2) * params.crop_ratio, size(im, 1) * params.crop_ratio]);

% Apply median filter
if params.median_filter_radius > 0
    filtered = medfilt2(unfiltered, [params.median_filter_radius params.median_filter_radius]);
else
    filtered = unfiltered;
end

end