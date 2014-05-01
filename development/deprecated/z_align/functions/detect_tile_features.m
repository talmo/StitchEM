function features = detect_tile_features(tile_img, varargin)
%DETECT_TILE_FEATURES Returns tile points and descriptors.
% Usage:
%   features = DETECT_TILE_FEATURES(tile_img)
%   features = DETECT_TILE_FEATURES(..., 'Name', Value)
% 
% Name-Value pairs:
%   pre_scale = 1.0 % scale the tile image is in
%   detection_scale = 0.25 % scale to detect in
%   MetricThreshold = 5000
%   NumOctave = 3
%   NumScaleLevels = 4
%   SURFSize = 64
%   show_features = false % visualization

%% Pre-processing
% Parse inputs
[tile_img, params] = parse_inputs(tile_img, varargin{:});

tic
% Resize tile image to detection scale
if params.pre_scale ~= params.detection_scale
    tile_img = imresize(tile_img, params.pre_scale * params.detection_scale);
    if params.verbosity > 0
        fprintf('Resized tile to detection scale: pre_scale = %s | detection_scale = %s\n', num2str(params.pre_scale), num2str(params.detection_scale))
    end
end

%% SURF feature detection
% Find interest points
interest_points = detectSURFFeatures(tile_img, ...
    'MetricThreshold', params.MetricThreshold, ...
    'NumOctave', params.NumOctave, ...
    'NumScaleLevels', params.NumScaleLevels);

% Get descriptors from pixels around interest points
[descriptors, valid_points] = extractFeatures(tile_img, ...
    interest_points, 'SURFSize', params.SURFSize);

% Save valid points, i.e., points with descriptors
local_points = valid_points(:).Location;
num_features = size(local_points, 1);
detect_time = toc;
if params.verbosity > 0
    fprintf('Detected %d features in tile. [%.2fs]\n', num_features, detect_time);
end

%% Post-process SURF output
% Calculate transform to scale points up to original resolution
tform_rescale = scale_tform(1 / params.detection_scale);

% Apply them to the points to get the local coordinates in original resolution
local_points = tform_rescale.transformPointsForward(local_points);

% Put everything in a table before returning
features = table(local_points, descriptors);

%% Visualization
if params.show_features
    % Display the tile (tile_img is at detection scale by this point)
    figure, imshow(tile_img), hold on
    title(sprintf('Local Features (n = %d | detection scale = %s)', num_features, num2str(params.detection_scale)))
    
    % Scale and plot the local points
    plot_features(local_points, params.detection_scale);
    integer_axes(1/params.detection_scale);
    hold off
end

end

function [tile_img, params] = parse_inputs(tile_img, varargin)
% Create inputParser instance
p = inputParser;

% Required parameters
p.addRequired('tile_img');

% Scaling
p.addParameter('pre_scale', 1.0); % Scale the tile image is in
p.addParameter('detection_scale', 0.25); % Scale to detect in

% Detection
p.addParameter('MetricThreshold', 5000); % MATLAB default = 1000
p.addParameter('NumOctave',  3); % MATLAB default = 3
p.addParameter('NumScaleLevels', 4); % MATLAB default = 4
p.addParameter('SURFSize', 64); % MATLAB default = 64

% Visualization and debugging
p.addParameter('show_features', false);
p.addParameter('verbosity', 0);

% Validate and parse input
p.parse(tile_img, varargin{:});
tile_img = p.Results.tile_img;
params = rmfield(p.Results, 'tile_img');
end