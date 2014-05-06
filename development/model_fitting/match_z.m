function matches = match_z(secA, secB)
%MATCH_Z Finds Z matches betwen two sections.
% Usage:
%   z_matches = match_z(secA, secB)

% Process parameters
[params, unmatched_params] = parse_input(sec, varargin{:});



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