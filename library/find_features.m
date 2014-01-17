function [points, descriptors] = find_features(image, method, regions, method_params)
%FIND_FEATURES Finds distinct features in an image.
% image should be a grayscale intensity image
% method should be 'sift' or 'surf'
% method_params is a structure with the parameters for the method chosen.
% regions is a cell array of [top left height width] arrays defining
%   which regions within the image to search for features.

%% Validate arguments
% Check method
method = lower(method);
if ~strcmp(method, 'sift') && ~strcmp(method, 'surf')
    error('Method for feature detection must be SIFT or SURF.')
end
% Check regions
if nargin < 3
    regions = {[1 1 size(image, 1) size(image, 2)]}; % defaults to entire image
end
if nargin >= 3
    if ~iscell(regions)
        regions = num2cell(regions, 2); % convert to cell array of rows
    end
end
% Check feature detector parameters
if strcmp(method, 'sift')
    detector_params = struct();
elseif strcmp(method, 'surf')
    % arguments for detectSURFFeatures
    detector_params.detect.MetricThreshold = 5000;
    detector_params.detect.NumOctave = 3;
    detector_params.detect.NumScaleLevels = 4;
    % arguments for extractFeatures
    detector_params.extract.SURFSize = 64;
end
if nargin >= 4
    f = fieldnames(method_params);
    for i = 1:length(f)
      detector_params = setfield(detector_params, f{i}, getfield(method_params, f{i}));
    end
end

%% Find features in each region
points = {};
descriptors = {};
for region = regions
    region = region{1};
    % Get region from the image
    img_region = image(region(1) : region(1) + region(3) - 1, ...
                       region(2) : region(2) + region(4) - 1);
    
    % SIFT
    if strcmp(method, 'sift')
        % TODO
    end
    
    % SURF
    if strcmp(method, 'surf')
        % Find interest points
        args = struct2args(detector_params.detect);
        interest_points = detectSURFFeatures(img_region, args{:});
        
        % Get descriptors from pixels around interest points
        args = struct2args(detector_params.extract);
        [region_descriptors, valid_points] = extractFeatures(img_region, ...
            interest_points, args{:});
        
        % Adjust coordinate of region points to image coordinates
        valid_points(:).Location = valid_points(:).Location + ...
                [repmat(region(1) - 1, length(valid_points), 1) ...
                 repmat(region(3) - 1, length(valid_points), 1)];
        
        % Append to list of points and descriptors
        points = [points; num2cell(valid_points(:).Location, 2)];
        descriptors = [descriptors; num2cell(region_descriptors, 2)];
    end
end
end

%% Helper functions
% Converts a structure into a cell array of fields and values
% -> Useful for unpacking a structure into arguments for a function call
function p = struct2args(s)
fieds = fieldnames(s);
values = struct2cell(s);
p = [fieds, values]';
p = p(:); % flatten
end