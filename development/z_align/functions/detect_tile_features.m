function features = detect_tile_features(tile, varargin)
%DETECT_TILE_FEATURES Returns tile points and descriptors.
% Usage:
%   features = detect_tile_features(tile); % tile an intensity image array
% 
% Name-value pairs and defaults:
%   tile_scale_ratio = 0.20
%   MetricThreshold = 10000
%   NumOctave = 3
%   NumScaleLevels = 4
%   SURFSize = 64
%   show_features = false

%% Pre-processing
% Parse inputs
[tile, params] = parse_inputs(tile, varargin{:});

tic
% Resize tile image
if params.tile_scale_ratio ~= 1.0
    tile = imresize(tile, params.tile_scale_ratio);
end

%% SURF feature detection
% Find interest points
interest_points = detectSURFFeatures(tile, ...
    'MetricThreshold', params.MetricThreshold, ...
    'NumOctave', params.NumOctave, ...
    'NumScaleLevels', params.NumScaleLevels);

% Get descriptors from pixels around interest points
[descriptors, valid_points] = extractFeatures(tile, ...
    interest_points, 'SURFSize', params.SURFSize);

% Save valid points, i.e., points with descriptors
local_points = valid_points(:).Location;
num_features = size(local_points, 1);
detect_time = toc;
if params.verbosity > 0
    fprintf('Detected %d features in tile. [%.2fs]\n', num_features, detect_time);
end

%% Post-process SURF output
if params.tile_scale_ratio ~= 1.0
    % Calculate transform to scale points up to original resolution
    tform_rescale = scale_tform(1 / params.tile_scale_ratio);

    % Apply them to the points to get the local coordinates in original resolution
    local_points = tform_rescale.transformPointsForward(local_points);
end

% Put everything in a table before returning
features = table(local_points, descriptors);

%% Visualization
if params.show_features
    % Display the tile
    figure, imshow(tile), hold on
    title(sprintf('Local Features (n = %d)', num_features))
    
    % Plot the points found
    plot(local_points(:, 1), local_points(:, 2), 'rx')
end

end

function [tile, params] = parse_inputs(tile, varargin)
% Create inputParser instance
p = inputParser;

% Required parameters
p.addRequired('tile');

% Pre-processing
p.addParameter('tile_scale_ratio', 0.20);

% Detection
p.addParameter('MetricThreshold', 10000); % MATLAB default = 1000
p.addParameter('NumOctave',  3); % MATLAB default = 3
p.addParameter('NumScaleLevels', 4); % MATLAB default = 4
p.addParameter('SURFSize', 64); % MATLAB default = 64

% Visualization and debugging
p.addParameter('show_features', false);
p.addParameter('verbosity', 0)

% Validate and parse input
p.parse(tile, varargin{:});
tile = p.Results.tile;
params = rmfield(p.Results, 'tile');
end