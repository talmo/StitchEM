function [tile_tform, tforms, varargout] = estimate_tile_alignment(tile_img, overview_img, varargin)
%ESTIMATE_TILE_ALIGNMENT Finds a transform that aligns a tile to its montage overview to initialize its placement.
% To get a rough alignment for a tile based on its position in its overview:
%   tile_tform = estimate_tile_alignment(tile_img, overview_img);
%
% Optionally, if the overview was already registered to another section's
% overview, simply pass in the pre-computed transformation:
%   tile_tform = estimate_tile_alignment(tile_img, overview_img, tform_overview);
%
% Optional name-value pairs and their defaults:
%   overview_scale = 0.5
%   overview_crop_ratio = 0.5
%   tile_scale = 0.05
%   show_registration = false

% Parse inputs
[tile_img, overview_img, tform_overview, params, unmatched_params] = parse_inputs(tile_img, overview_img, varargin{:});

% Pre-process the images
[tile, overview] = pre_process(tile_img, overview_img, params);

% (Try to) register the tile to the overview image
try
    % Try registering with any custom registration parameters
    tform_registration = surf_register(overview, tile, unmatched_params);
catch err
    if ~isempty(params.surf_register_params)
        % We failed to register with custom params, try with default
        try
            %disp('Tile registration with custom parameters failed. Trying defaults.')
            tform_registration = surf_register(overview, tile, 'default', 'verbosity', 0);
        catch err2
            % We failed to register with default params, try fallback
            fallback_registration(overview, tile, err2);
        end
    else
        % We failed to register with default params, try fallback
        fallback_registration(overview, tile, err);
    end
end

% Check for signs of bad registration in the transform
[reg_scale, ~, reg_translation] = estimate_tform_params(tform_registration);
if reg_scale > 2.0
    warning('Tile registration to its overview appears to be very oddly scaled. Check the registration results.')
end
if any(reg_translation > size(overview))
    warning('Tile registration to its overview appears to be very oddly translated. Check the registration results.')
end

% Calculate the scaling transforms
tform_prescale = scale_tform(params.tile_scale);
tform_rescale = scale_tform(1 / (reg_scale * params.tile_scale));

% Compose the final tform:
% Prescale -> Register to overview -> Register overview to other overview -> Rescale
tile_tform = affine2d(tform_prescale.T * tform_registration.T * tform_overview.T * tform_rescale.T);

% Return the intermediate transforms as a secondary output argument
tforms.prescale = tform_prescale;
tforms.registration = tform_registration;
tforms.overview = tform_overview;
tforms.rescale = tform_rescale;

%% Visualization
if params.show_registration
    % Calculate tile transform without prescaling or rescaling
    tform_tile_unscaled = affine2d(tform_registration.T * tform_overview.T);
    
    % Apply transforms to images
    [overview, overview_spatial_ref] = imwarp(overview, tform_overview);
    [tile, tile_spatial_ref] = imwarp(tile, tform_tile_unscaled);
    
    % Merge and display results
    [merge, merge_spatial_ref] = imfuse(overview, overview_spatial_ref, tile, tile_spatial_ref);
    imshow(merge, merge_spatial_ref);
    
    % Return visualizations
    visualization.merge = merge;
    visualization.merge_spatial_ref = merge_spatial_ref;
    visualization.overview = overview;
    visualization.overview_spatial_ref = overview_spatial_ref;
    visualization.tile = tile;
    visualization.tile_spatial_ref = tile_spatial_ref;
    varargout = {visualization};
end

end

function [tile, overview] = pre_process(tile_img, overview_img, params)
% Resize
tile = imresize(tile_img, 1 / params.tile_pre_scale * params.tile_scale);
overview = imresize(overview_img, params.overview_scale);

% Crop to center
overview = imcrop(overview, [size(overview, 2) * (params.overview_crop_ratio / 2), size(overview, 1) * (params.overview_crop_ratio / 2), size(overview, 2) * params.overview_crop_ratio, size(overview, 1) * params.overview_crop_ratio]);

end

function tform_registration = fallback_registration(overview, tile, err)
% Try different parameters for registration if it failed
switch err.identifier
    case 'surf_register:notEnoughPotentialMatches'
        %disp('Could not find enough potential matches to reliably register tile to overview.')
        %disp('Trying different parameters for feature detection.')
        
        % Smooth out possible artifacts using a median filter
        median_filter_radius = 6;
        filtered_overview = medfilt2(overview, [median_filter_radius, median_filter_radius]);
        filtered_tile = medfilt2(tile, [median_filter_radius, median_filter_radius]);
        
        % Try the registration again with fallback params
        tform_registration = surf_register(filtered_overview, filtered_tile, 'fallback2', 'verbosity', 0);
        
    case 'surf_register:notEnoughInliers'
        %disp('Could not find enough inliers to reliably register tile to overview.')
        %disp('Trying different parameters for inlier detection.')
        
        % Smooth out possible artifacts using a median filter
        median_filter_radius = 6;
        filtered_overview = medfilt2(overview, [median_filter_radius, median_filter_radius]);
        filtered_tile = medfilt2(tile, [median_filter_radius, median_filter_radius]);
        
        % Try the registration again with fallback params
        tform_registration = surf_register(filtered_overview, filtered_tile, 'fallback1', 'verbosity', 0);
    otherwise
        rethrow(err)
end
end

function [tile_img, overview_img, tform_overview, params, unmatched] = parse_inputs(tile_img, overview_img, varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Required parameters
p.addRequired('tile_img');
p.addRequired('overview_img');

% If no transform is passed in, just register it without change
p.addOptional('tform_overview', affine2d());

% Overview pre-processing
p.addParameter('overview_scale', 0.78);
p.addParameter('overview_crop_ratio', 0.5);

% Scaling
p.addParameter('tile_pre_scale', 1.0);
p.addParameter('tile_scale', 0.78 * 0.07);

% Visualization
p.addParameter('show_registration', false);

% Debugging
p.addParameter('verbosity', 0);

% Validate and parse input
p.parse(tile_img, overview_img, varargin{:});
tile_img = p.Results.tile_img;
overview_img = p.Results.overview_img;
tform_overview = p.Results.tform_overview;
params = rmfield(p.Results, {'tile_img', 'overview_img', 'tform_overview'});
unmatched = p.Unmatched;
end