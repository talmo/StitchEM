function matches = nnr_match(A, B, varargin)
%NNR_MATCH Matches two sets of features using Nearest Neighbor Ratio.
%
% Usage:
%   matches = nnr_match(A, B)
%   matches = nnr_match(A, B, ...)
%
% Args:
%   A and B are two potentially matching feature sets. These are tables
%       in the format returned by detect_surf_features. Must contain a
%       column named 'descriptors'.
%
% Parameters ('Name', Default):
%   'out', 'index': Determines the type of output to return.
%       'index' = the indices to the matching features
%       'rows' = the entire rows of feature tables that are matching
%       'rows-nodesc' = same as 'rows' but drops the descriptor column
%   'verbosity', 1: Controls how much to output to the console.
%
% Also accepts Name, Value parameters for:
%   matchFeatures
%
% Returns:
%   matches is a structure with the fields: A and B. These contain the
%       output as specified by parameter 'out'. It also contains the fields
%       metric and metric_type.
%
% See also: matchFeatures, detect_surf_features

% Process parameters
[params, unmatched_params] = parse_input(varargin{:});
if ~instr('descriptors', A.Properties.VariableNames) || ...
        ~instr('descriptors', B.Properties.VariableNames)
   error('Features sets must have a descriptors column.')
end

% matchFeatures defaults - these are overwritten with any other parameters
%   passed in to this function
default_params.Prenormalized = true; % SURF descriptors are prenormalized
default_params.MaxRatio = 0.6;
default_params.MatchThreshold = 1.0;
default_params.Metric = 'SSD';

% Match using NNR
[indexPairs, matchMetric] = matchFeatures(A.descriptors, B.descriptors, default_params, unmatched_params);

% Return specified output type
switch params.out
    case 'index'
        matches.A = indexPairs(:, 1);
        matches.B = indexPairs(:, 2);
    case 'rows'
        matches.A = A(indexPairs(:, 1), :);
        matches.B = B(indexPairs(:, 2), :);
    case 'rows-nodesc'
        nodesc = ~strcmp('descriptors', feats.Properties.VariableNames);
        matches.A = A(indexPairs(:, 1), nodesc);
        matches.B = B(indexPairs(:, 2), nodesc);
end

% Metric fields
matches.metric = matchMetric;
matches.metric_type = default_params.Metric;
if isfield(unmatched_params, 'Metric'); matches.metric_type = unmatched_params.Metric; end

end

function [params, unmatched] = parse_input(varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Output types
out_types = {'index', 'rows', 'rows-nodesc'};
p.addParameter('out', 'index', @(x) validatestring(x, out_types));

% Verbosity
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;

end