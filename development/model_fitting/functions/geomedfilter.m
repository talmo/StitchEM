function [inliers, outliers] = geomedfilter(displacements, varargin)
%GEOMEDFILTER Filters a set of point displacements based on their distance from the geometric median.
% Usage:
%   [inliers, outliers] = geomedfilter(displacements)

% Process parameters
[params, unmatched_params] = parse_input(varargin{:});

if isempty(params.expected_median)
    % Calculate the geometric median
    M = geomedian(displacements);
else
    % Use the given value
    M = params.expected_median;
end

% Calculate the distance of each point from the geometric median
[~, distances] = rownorm2(bsxadd(displacements, -M));

% Filter outliers
switch params.filter
    case 'hardthreshold'
        if ischar(params.threshold) && instr('x', params.threshold)
            thresh = str2double(params.threshold(1:end-1)) * median(distances);
        else
            thresh = params.threshold;
        end
        
        inliers = find(distances <= thresh);
        outliers = find(distances > thresh);
end

end

function [params, unmatched] = parse_input(varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Expected median
p.addOptional('expected_median', []);

% Filter type
filter_types = {'hardthreshold'};
p.addParameter('filter', 'hardthreshold');

% Thresholding
p.addParameter('threshold', '3x');

% Verbosity
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;
params.filter = validatestring(params.filter, filter_types);

end