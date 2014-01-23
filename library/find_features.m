function [points, descriptors] = find_features(image, method, regions, parameters)
%FIND_FEATURES Finds distinct features in an image.
% image should be a grayscale intensity image
% method should be 'sift' or 'surf'
% parameters is a structure with the parameters for the method chosen.
% regions is a cell array of [top left height width] arrays defining
%   which regions within the image to search for features.
% test.

%% Validate arguments
% Check method
if nargin < 2
    method = 'surf';
end
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
        if size(regions) == [1 2]
            regions = [1 1 regions(1) regions(2)]; % user passed size(img)
        end
        regions = num2cell(regions, 2); % convert to cell array of rows
    end
end
% Check feature detector parameters
if strcmp(method, 'sift')
    params = struct();
elseif strcmp(method, 'surf')
    % Default arguments for detectSURFFeatures
    params.detect.MetricThreshold = 5000;
    params.detect.NumOctave = 3;
    params.detect.NumScaleLevels = 4;
    
    % Default arguments for extractFeatures
    params.extract.SURFSize = 64;
end
% Overwrite defaults with any parameters passed in
if nargin >= 4
    f = fieldnames(parameters); % fields
    for i = 1:length(f)
        sf = fieldnames(parameters.(f{i})); % subfields
        for e = 1:length(sf)
            params.(f{i}).(sf{e}) = parameters.(f{i}).(sf{e});
        end
    end
end

%% Find features in each region
% Pre-allocate containers
points = zeros(10000, 2, 'single');
descriptors = zeros(10000, 64, 'single');
num_points = 0;

% Find features in each region
for i = 1:numel(regions)
    region = regions{i};
    % Get region from the image where region = [top left width height]
    img_region = image(region(1) : region(1) + region(3) - 1, ...
                       region(2) : region(2) + region(4) - 1);
    
    % SIFT
    if strcmp(method, 'sift')
        % TODO
    end
    
    % SURF
    if strcmp(method, 'surf')
        % Find interest points
        args = struct2args(params.detect);
        interest_points = detectSURFFeatures(img_region, args{:});
        
        % Get descriptors from pixels around interest points
        args = struct2args(params.extract);
        [region_descriptors, valid_points] = extractFeatures(img_region, ...
            interest_points, args{:});
        
        % Count number of "valid" points with descriptors
        num_points_in_region = length(valid_points);
        
        % Adjust coordinate of region points to image coordinates
        valid_points(:).Location = valid_points(:).Location + ...
                [repmat(region(1) - 1, num_points_in_region, 1) ...
                 repmat(region(2) - 1, num_points_in_region, 1)];
        
        % Save to containers of points and descriptors
        points(num_points + 1 : num_points + num_points_in_region, :) = ...
            valid_points(:).Location;
        descriptors(num_points + 1 : num_points + num_points_in_region, :) = ...
            region_descriptors;
        num_points = num_points + num_points_in_region;
    end
end

% Trim container arrays down to fit actual number of features found
points = points(1 : num_points, :);
descriptors = descriptors(1 : num_points, :);

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