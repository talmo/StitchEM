function [matchesA, matchesB] = match_section_features(sec, varargin)
%MATCH_SECTION_FEATURES Find matches between neighboring tiles of a section.

% Parse input
[params, unmatched_params] = parse_inputs(varargin{:});

total_time = tic;
if params.verbosity > 0
    fprintf('== Matching XY features in section %d.\n', sec.num)
end

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
        match_time = tic;
        
        % Find overlap between the two tiles
        overlap = calculate_overlaps(sec.rough_tforms([i, j]));

        % Get features in region
        featuresA = filter_features(sec.xy_features, i, overlap{1});
        featuresB = filter_features(sec.xy_features, j, overlap{1});

        % Match
        [mA, mB] = match_feature_sets(featuresA, featuresB, ...
            'region_size', params.region_size, 'MatchThreshold', params.MatchThreshold, ...
            'MaxRatio', params.MaxRatio, 'filter_inliers', params.filter_inliers, ...
            unmatched_params);

        % Save results
        matchesA = [matchesA; mA]; matchesB = [matchesB; mB];
        
        if params.verbosity > 1
            fprintf('Found %d matches between tiles %d <-> %d. [%.2fs]\n', height(mA), i, j, toc(match_time))
        end
    end
end

% Add match scale column
num_matches = height(matchesA);
matchesA.scale = repmat(sec.tile_xy_scale, num_matches, 1);
matchesB.scale = repmat(sec.tile_xy_scale, num_matches, 1);

if params.verbosity > 0
    fprintf('Found %d total XY matches. [%.2fs]\n', num_matches, toc(total_time))
end

if params.show_matches
    figure
    imshow_section(sec, 'display_scale', params.display_scale);
    hold on
    plot_matches(matchesA, matchesB, params.display_scale);
    integer_axes(1 / params.display_scale)
    hold off
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

% XY matching parameters
p.addParameter('region_size', 0);
p.addParameter('MatchThreshold', 0.2);
p.addParameter('MaxRatio', 0.6);
p.addParameter('filter_inliers', false);

% Verbosity
p.addParameter('verbosity', 1);

% Visualization
p.addParameter('show_matches', false);
p.addParameter('display_scale', 0.075);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;
end