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
% Parameters:
%   Nearest Neighbor Ratio (matchFeatures()):
%   'NNR', NNR_params: struct with the fields MaxRatio and MatchThreshold
%   'MaxRatio', 0.6: NNR Max Ratio (see matchFeatures())
%   'MatchThreshold', 1.0: NNR Match Threshold (see matchFeatures())
%
%   Others:
%   'out', 'index': Determines the type of output to return.
%       Out modes:
%       'index' = the indices to the matching features
%       'rows' = the entire rows of feature tables that are matching
%       'rows-nodesc' = same as 'rows' but drops the descriptor column
%   'verbosity', 1: Controls how much to output to the console.
%
% Returns:
%   matches is a structure with the fields: A and B. These contain the
%       output as specified by parameter 'out'. It also contains the fields
%       metric and metric_type.
%
% See also: match_z, matchFeatures, detect_surf_features

% Process parameters
params = parse_input(varargin{:});
if ~instr('descriptors', A.Properties.VariableNames) || ...
        ~instr('descriptors', B.Properties.VariableNames)
   error('Features sets must have a descriptors column.')
end

% Match using NNR
[indexPairs, matchMetric] = matchFeatures(A.descriptors, B.descriptors, params.NNR);

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
matches.metric_type = params.NNR.Metric;

end

function params = parse_input(varargin)

% Create inputParser instance
p = inputParser;

% NNR (matchFeatures)
NNR_defaults = struct();
NNR_defaults.Prenormalized = true; % SURF descriptors are prenormalized
NNR_defaults.Metric = 'SSD';
NNR_defaults.MaxRatio = 0.6;
NNR_defaults.MatchThreshold = 1.0;
p.addParameter('NNR', NNR_defaults, @(x) isstruct(x) && all(instr(fieldnames(x), fieldnames(NNR_defaults), 'a')));
for f = fieldnames(NNR_defaults)'
    p.addParameter(f{1}, NNR_defaults.(f{1}));
end

% Output types
out_types = {'index', 'rows', 'rows-nodesc'};
p.addParameter('out', 'index', @(x) validatestr(x, out_types));

% Verbosity
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

% Overwrite struct values if NNR params passed explicitly
for f = fieldnames(NNR_defaults)'
    if ~instr(f{1}, fieldnames(params.NNR))
        params.NNR.(f{1}) = NNR_defaults.(f{1});
    end
    if ~instr(f{1}, p.UsingDefaults)
        params.NNR.(f{1}) = params.(f{1});
    end
    % Keep the "official copy" of the NNR params in the NNR structure to
    % avoid ambiguity
    params = rmfield(params, f{1});
end
end