function matches = match_xy(sec, varargin)
%MATCH_XY Finds XY matches within a section.
% Usage:
%   sec.xy_matches = match_xy(sec)

% Process parameters
[params, unmatched_params] = parse_input(sec, varargin{:});
features = sec.features.(params.feature_set);

% Match each tile pair
match_sets = {};
match_idx = cell(sec.num_tiles);
for tA = 1:sec.num_tiles - 1
    for tB = tA + 1:sec.num_tiles
        % Get putatively matching feature sets
        featsA = features.tiles{tA};
        featsB = features.tiles{tB};
        
        % Skip if either set is empty
        if isempty(featsA) || isempty(featsB)
            continue
        end
        
        % Match using Nearest-Neighbor Ratio
        match_set = nnr_match(featsA, featsB, unmatched_params);
        
        % Filter based on distance from median
        if params.filter_outliers
            displacements = featsB.global_points(match_set.B, :) ...
                          - featsA.global_points(match_set.A, :);
            [inliers, outliers] = geomedfilter(displacements, unmatched_params);
            
            match_set.A = match_set.A(inliers);
            match_set.B = match_set.B(inliers);
        end
        
        % Save matches
        match_sets{end + 1} = match_set;
        match_idx{tA, tB} = length(match_sets);
        match_idx{tB, tA} = length(match_sets);
    end
end

% Save to output structure
matches.match_sets = match_sets;
matches.tile_idx = match_idx;
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