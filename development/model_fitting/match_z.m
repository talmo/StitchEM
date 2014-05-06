function matches = match_z(secA, secB)
%MATCH_Z Finds Z matches betwen two sections.
% Usage:
%   z_matches = match_z(secA, secB)

% Process parameters
[params, unmatched_params] = parse_input(sec, varargin{:});

% Find matches between pairs of tiles
match_sets = {};
match_idx = cell(secA.num_tiles, secB.num_tiles);
for tA = 1:secA.num_tiles
    for tB = 1:secB.num_tiles
        
    end
end

end

function [params, unmatched] = parse_input(sec, varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Feature set
feature_sets = fieldnames(sec.features);
p.addParameter('feature_set', 'xy', @(x) validatestring(x, feature_sets));

% Verbosity
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;

end