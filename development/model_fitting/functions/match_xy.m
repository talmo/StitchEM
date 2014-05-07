function matches = match_xy(sec, varargin)
%MATCH_XY Finds XY matches within a section.
% Usage:
%   sec.xy_matches = match_xy(sec)

% Process parameters
[params, unmatched_params] = parse_input(sec, varargin{:});
features = sec.features.(params.feature_set);

if params.verbosity > 0; fprintf('== Matching XY features in section %d.\n', sec.num); end
total_time = tic;

% Match each tile pair
match_sets = {};
match_idx = cell(sec.num_tiles);
num_matches = 0;
for tA = 1:sec.num_tiles - 1
    % Get tile A features
    tileA_features = features.tiles{tA};
    for tB = tA + 1:sec.num_tiles
        % Look for overlap region between the tiles
        overlap_regionA = find(features.meta.overlap_with{tA} == tB, 1);
        overlap_regionB = find(features.meta.overlap_with{tB} == tA, 1);
        
        % Skip this tile pair if they do not overlap
        if isempty(overlap_regionA) || isempty(overlap_regionB)
            continue
        end
        
        % Get tile B features
        tileB_features = features.tiles{tB};
        
        % Get only the features in the overlap regions
        featsA = tileA_features(tileA_features.region == overlap_regionA, :);
        featsB = tileB_features(tileB_features.region == overlap_regionB, :);
        
        % Match using Nearest-Neighbor Ratio
        match_set = nnr_match(featsA, featsB, unmatched_params);
        
        % Filter based on distance from median
        if params.filter_outliers
            displacements = featsB.global_points(match_set.B, :) ...
                          - featsA.global_points(match_set.A, :);
            [inliers, outliers] = geomedfilter(displacements, unmatched_params);
            
            match_set.A = match_set.A(inliers);
            match_set.B = match_set.B(inliers);
            match_set.metric = match_set.metric(inliers);
        end
        
        % Get table data from matched indices
        match_set.A = featsA(match_set.A, params.keep_cols);
        match_set.B = featsB(match_set.B, params.keep_cols);
        
        % Metadata
        match_set.tileA = tA;
        match_set.tileB = tB;
        match_set.num_matches = height(match_set.A);
        
        % Save matches
        match_sets{end + 1, 1} = match_set;
        match_idx{tA, tB} = length(match_sets);
        match_idx{tB, tA} = length(match_sets);
        num_matches = num_matches + match_set.num_matches;
    end
end

% Save to output structure
matches.match_sets = match_sets;
matches.tile_idx = match_idx;
matches.feature_set = params.feature_set;
matches.num_matches = num_matches;
matches.sec = sec.num;

if params.verbosity > 0; fprintf('Found %d matches. [%.2fs]\n', num_matches, toc(total_time)); end

end

function [params, unmatched] = parse_input(sec, varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Feature set
feature_sets = fieldnames(sec.features);
p.addParameter('feature_set', 'xy', @(x) validatestring(x, feature_sets));

% Filter outliers
p.addParameter('filter_outliers', true);

% Columns to keep for the matched features
p.addParameter('keep_cols', {'local_points', 'global_points'});

% Verbosity
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;
params.feature_set = validatestring(params.feature_set, feature_sets);

end