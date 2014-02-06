function [points, descriptors] = find_features(image, region, parameters)
%FIND_FEATURES Finds distinct features in an image.


%% Parameters
% Default parameters
params.method = 'surf';
params.surf.MetricThreshold = 5000;
params.surf.NumOctave = 3;
params.surf.NumScaleLevels = 4;
params.surf.SURFSize = 64;

if isfield(parameters.surf, 'MetricThreshold')
    params.surf.MetricThreshold = parameters.surf.MetricThreshold;
end
% Check method
% if nargin < 2
%     method = 'surf';
% end
% method = lower(method);
% if ~strcmp(method, 'sift') && ~strcmp(method, 'surf')
%     error('Method for feature detection must be SIFT or SURF.')
% end
% % Check regions
% if nargin < 3
%     regions = {[1 1 size(image, 1) size(image, 2)]}; % defaults to entire image
% end
% if nargin >= 3
%     if ~iscell(regions)
%         if size(regions) == [1 2]
%             regions = [1 1 regions(1) regions(2)]; % user passed size(img)
%         end
%         regions = num2cell(regions, 2); % convert to cell array of rows
%     end
% end
% % Check feature detector parameters
% if strcmp(method, 'sift')
%     params = struct();
% elseif strcmp(method, 'surf')
%     % Default arguments for detectSURFFeatures
%     params.detect.MetricThreshold = 5000;
%     params.detect.NumOctave = 3;
%     params.detect.NumScaleLevels = 4;
%     
%     % Default arguments for extractFeatures
%     params.extract.SURFSize = 64;
% end
% Overwrite defaults with any parameters passed in
% if nargin >= 4
%     f = fieldnames(parameters); % fields
%     for i = 1:length(f)
%         sf = fieldnames(parameters.(f{i})); % subfields
%         for e = 1:length(sf)
%             params.(f{i}).(sf{e}) = parameters.(f{i}).(sf{e});
%         end
%     end
% end

%% Find features in each region
% Get specified region from the image
img_region = image(region.top : region.top + region.height - 1, ...
                   region.left : region.left + region.width - 1);

% SURF
if strcmp(params.method, 'surf')
    % Find interest points
    interest_points = detectSURFFeatures(img_region, ...
        'MetricThreshold', params.surf.MetricThreshold, ...
        'NumOctave', params.surf.NumOctave, ...
        'NumScaleLevels', params.surf.NumScaleLevels);

    % Get descriptors from pixels around interest points
    [descriptors, valid_points] = extractFeatures(img_region, ...
        interest_points, ...
        'SURFSize', params.surf.SURFSize);

    % Adjust coordinate of region points to image coordinates
    valid_points(:).Location = valid_points(:).Location + ...
            [repmat(region.left  - 1, length(valid_points), 1) ... % X offset
             repmat(region.top - 1, length(valid_points), 1)];     % Y offset

    % Save valid and adjusted points
    points = valid_points(:).Location;

% SIFT
elseif strcmp(params.method, 'sift')
    % TODO
end

end