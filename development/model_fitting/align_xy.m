function alignment = align_xy(sec, varargin)
%ALIGN_XY Aligns the tiles of a section in XY.

% Process parameters
[params, unmatched_params] = parse_input(varargin{:});


end

function [params, unmatched] = parse_input(varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

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