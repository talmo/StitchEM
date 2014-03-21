function [matchesA, matchesB] = match_section_features(sec, varargin)
%MATCH_SECTION_FEATURES Find matches between neighboring tiles of a section.

% Parse input
[params, unmatched_params] = parse_inputs(varargin{:});

% Loop through tiles
matchesA = []; matchesB = [];
for i = 1:sec.num_tiles - 1
    % Find neighbors
    neighbors = find(find_neighbors(i));
    
    for j = i + 1:sec.num_tiles
        % Check if they are overlapping
        if ~any(neighbors == j)
            continue
        end
        tic;
        
        % Find overlap between the two tiles
        overlap = calculate_overlaps(sec.rough_alignments([i, j]));

        % Get features in region
        featuresA = filter_features(sec.features, i, overlap{1});
        featuresB = filter_features(sec.features, j, overlap{1});

        % Match
        [mA, mB] = match_feature_sets(featuresA, featuresB, ...
            'filter_inliers', true, 'MatchThreshold', 1.0, 'MaxRatio', 0.9, unmatched_params);

        % Save results
        matchesA = [matchesA; mA]; matchesB = [matchesB; mB];

        fprintf('Found %d matches between tiles %d <-> %d. [%.2fs]\n', height(mA), i, j, toc)
    end
end


end

function region_features = filter_features(features, tile, region)
in_tile = find(features.tile == tile);
in_region = inpolygon(features.global_points(in_tile, 1), features.global_points(in_tile, 2), region(:, 1), region(:, 2));

region_features = features(in_tile(in_region), :);
end

function [params, unmatched] = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Visualization
p.addParameter('show_matches', false);
p.addParameter('show_outliers', false);
p.addParameter('show_regions', false);
p.addParameter('display_scale', 0.075);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;
end