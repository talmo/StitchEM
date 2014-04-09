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
total_time = tic;

% Parse inputs
params = parse_inputs(varargin{:});

% Detect features in entire image by default
if isempty(params.regions)
    sz = size(tile_img) * (1 / params.pre_scale);
    params.regions = {[0,     0;     % top-left
                       0,     sz(2); % top-right
                       sz(1), sz(2); % bottom-right
                       sz(2), 0]};   % bottom-left
end

% Resize tile image to detection scale
if params.pre_scale ~= params.detection_scale
    tile_img = imresize(tile_img, params.pre_scale * params.detection_scale);
    if params.verbosity > 0
        fprintf('Resized tile to detection scale: pre_scale = %s | detection_scale = %s\n', num2str(params.pre_scale), num2str(params.detection_scale))
    end
end

% Initialize containers
local_points = cell(length(params.regions), 1);
descriptors = cell(length(params.regions), 1);

% Detect features in each region
for i = 1:length(params.regions)
    R = params.regions{i};
    
    % Get bounding box for at scaled to detection scale
    xy = min(R) * params.detection_scale;
    wh = (max(R) - min(R)) * params.detection_scale;
    
    % Calculate indices for bounding box
    row = max(round(xy(2)), 1) : min(round(xy(2) + wh(2)), size(tile_img, 1));
    col = max(round(xy(1)), 1) : min(round(xy(1) + wh(1)), size(tile_img, 2));
    
    % Extract image data from region
    img = tile_img(row, col);
    
    % Find interest points
    interest_points = detectSURFFeatures(img, ...
        'MetricThreshold', params.MetricThreshold, ...
        'NumOctaves', params.NumOctaves, ...
        'NumScaleLevels', params.NumScaleLevels);

    % Get descriptors from pixels around interest points
    [descriptors{i}, valid_points] = extractFeatures(img, ...
        interest_points, 'SURFSize', params.SURFSize);

    % Save valid points, i.e., points with descriptors
    local_pts = valid_points(:).Location;
    
    % Adjust point locations from region to tile
    local_pts = local_pts + repmat([col(1) - 1, row(1) - 1], size(local_pts, 1), 1);
    
    % Rescale to full resolution
    local_pts = local_pts * 1 / params.detection_scale;
    
    % Save
    local_points{i} = local_pts;
end

% Merge and build features table
local_points = vertcat(local_points{:});
descriptors = vertcat(descriptors{:});
features = table(local_points, descriptors);
num_features = height(features);

if params.verbosity > 0
    fprintf('Detected %d features in %d regions. [%.2fs]\n', num_features, length(regions), toc(total_time));
end

%% Visualization
if params.show_features
    % Display the tile (tile_img is at detection scale by this point)
    figure, imshow(tile_img), hold on
    title(sprintf('Local Features (n = %d | detection scale = %s | regions = %d)', num_features, num2str(params.detection_scale), length(params.regions)))
    
    % Scale and plot the local points
    plot_features(features.local_points, params.detection_scale);
    integer_axes(1/params.detection_scale);
    hold off
end

end

function params = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;

% Regions
p.addParameter('regions', {});

% Scaling
p.addParameter('pre_scale', 1.0); % Scale the tile image is in
p.addParameter('detection_scale', 0.25); % Scale to detect in

% Detection
p.addParameter('MetricThreshold', 5000); % MATLAB default = 1000
p.addParameter('NumOctaves',  3); % MATLAB default = 3
p.addParameter('NumScaleLevels', 4); % MATLAB default = 4
p.addParameter('SURFSize', 64); % MATLAB default = 64

% Visualization and debugging
p.addParameter('show_features', false);
p.addParameter('verbosity', 0);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
end