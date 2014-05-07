function features = detect_surf_features(img, varargin)
%DETECT_SURF_FEATURES Detects SURF features in an image.
%
% Usage:
%   features = detect_surf_features(img)
%   features = detect_surf_features(img, ...)
%
% Parameters ('Name', Default):
%   'regions', {}: Regions of the image to detect features in specified in
%       intrinsic coordinates. Leave empty to detect in entire image.
%   'pre_scale', 1.0: The scale of the image being passed in.
%   'detection_scale', 1.0: The scale to detect features in. If the
%       pre-scale of the image does not match this value, the image will be
%       automatically resized.
%   'verbosity', 1: Controls how much to output to the console.
%
% Also accepts Name, Value parameters for detectSURFFeatures
%
% See also: detect_features, detectSURFFeatures

% Parse inputs
[params, unmatched_params] = parse_input(varargin{:});

% Default to whole image if no region specified
if isempty(params.regions)
    params.regions = {sz2bb(size(img) / params.pre_scale)};
end
num_regions = numel(params.regions);

total_time = tic;
if params.verbosity > 0; fprintf('Detecting SURF features in %d regions at %sx scale.\n', num_regions, num2str(params.detection_scale)); end

% Resize image if needed
if params.pre_scale ~= params.detection_scale
    img = imresize(img, params.detection_scale / params.pre_scale);
end
sz = size(img);

% Initialize containers
local_points = cell(numel(params.regions), 1);
descriptors = cell(numel(params.regions), 1);

% Detect features in each region
for i = 1:num_regions
    % Scale region to detection scale
    region = params.regions{i} * params.detection_scale;
    
    % Find limits of the axis-aligned bounding box of the region
    [XLims, YLims] = bb2lims(region);
    
    % Convert intrinsic limits to subscripts
    [I, J] = intrinsicToSubscripts(XLims, YLims, sz);
    
    % Extract region from image
    img_region = img(I(1):I(2), J(1):J(2));
    
    % Get interest points
    interest_points = detectSURFFeatures(img_region, unmatched_params);

    % Extract descriptors from valid interest points
    [descriptors{i}, valid_points] = extractFeatures(img_region, interest_points);
    
    % Extract point locations
    local_points{i} = valid_points(:).Location;
    
    % Adjust for location of region
    region_offset = [J(1), I(1)] - [1, 1];
    local_points{i} = bsxadd(local_points{i}, region_offset);
    
    % Adjust for detection scale
    local_points{i} = local_points{i} / params.detection_scale;
    
    if params.verbosity > 1; fprintf('Found %d features in region %d.\n', height(local_points{i}), i); end
end

% Create region column
region = arrayfun(@(x) repmat(x, length(local_points{x}), 1), 1:num_regions, 'UniformOutput', false)';

% Merge into table
features = table(cell2mat(local_points), cell2mat(descriptors), cell2mat(region), ...
    'VariableNames', {'local_points', 'descriptors', 'region'});

if params.verbosity > 0; fprintf('Found %d features [%.2fs].\n', height(features), toc(total_time)); end
end

function [params, unmatched] = parse_input(varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Regions
p.addParameter('regions', {});

% Scale
p.addParameter('pre_scale', 1.0);
p.addParameter('detection_scale', 1.0);

% Verbosity
p.addParameter('verbosity', 0);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;

end