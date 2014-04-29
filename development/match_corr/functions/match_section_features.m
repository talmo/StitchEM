function [matchesA, matchesB, failed_tile_pairs] = match_section_features(sec, varargin)
%MATCH_SECTION_FEATURES Find matches between neighboring tiles of a section.

% Parse input
[params, unmatched_params] = parse_inputs(varargin{:});

total_time = tic;
if params.verbosity > 0
    fprintf('== Matching XY features in section %d.\n', sec.num)
end

% Loop through tiles
matchesA = {}; matchesB = {}; 
failed_tile_pairs = {}; num_matches = 0;
for i = 1:sec.num_tiles - 1
    % Find neighbor tiles
    neighbors = find(find_neighbors(i));
    
    for j = i + 1:sec.num_tiles
        % Check if tile j is a neighbor to tile i
        if ~any(neighbors == j)
            continue
        end
        match_time = tic;
        
        % Find overlap between the two tiles
        overlap = calculate_overlaps(sec.rough_tforms([i, j]));
        
        % Check if overlap any overlap was found
        if params.verbosity > 0 && isempty(overlap)
            warning('Could not find overlap region between adjacent tiles %d <-> %d. This may be a result of bad rough alignment.', i, j)
            failed_tile_pairs{end + 1} = [i, j];
            continue
        end

        % Get features in the overlap region
        featuresA = filter_features(sec.xy_features, i, overlap{1});
        featuresB = filter_features(sec.xy_features, j, overlap{1});
        
        % Check if enough features were found in the overlap region
        if params.verbosity > 0 && (height(featuresA) < params.min_region_feats || height(featuresB) < params.min_region_feats)
            warning('Too few features (%d < %d) in overlap region between tiles %d <-> %d. This may be a result of bad rough alignment.', height(featuresA), params.min_region_feats, i, j)
            failed_tile_pairs{end + 1} = [i, j];
            continue
        end

        % Match
        [mA, mB] = match_feature_sets(featuresA, featuresB, ...
            'region_size', params.region_size, 'MatchThreshold', params.MatchThreshold, ...
            'MaxRatio', params.MaxRatio, 'filter_inliers', params.filter_inliers, ...
            unmatched_params);
        
        % Count matches
        num_seam_matches = height(mA);
        num_matches = num_matches + num_seam_matches;
        
        % Save results
        matchesA{end + 1} = mA;
        matchesB{end + 1} = mB;
        
        if params.verbosity > 1 && height(mA) > 0
            fprintf('Found %d matches between tiles %d <-> %d. [%.2fs]\n', num_seam_matches, i, j, toc(match_time))
        end
        
        % Check for number of matches found
        if params.verbosity > 0 && num_seam_matches == 0
            warning('Found 0 matches between adjacent tiles %d <-> %d. This may be a result of bad rough alignment.', i, j)
            failed_tile_pairs{end + 1} = [i, j];
        end
    end
end

% Merge match tables
matchesA = vertcat(matchesA{:});
matchesB = vertcat(matchesB{:});

% Add match scale column
matchesA.scale = repmat(sec.tile_xy_scale, num_matches, 1);
matchesB.scale = repmat(sec.tile_xy_scale, num_matches, 1);

if params.verbosity > 0
    fprintf('Found %d total XY matches. [%.2fs]\n', num_matches, toc(total_time))
end

if params.show_matches
    figure, hold on
    % Render section
    imshow_section(sec, 'display_scale', params.display_scale);
    
    % Plot matches detected
    plot_matches(matchesA, matchesB, params.display_scale);
    
    % Adjust plot
    title(sprintf('Matches in section %d (n = %d)', sec.num, num_matches))
    integer_axes(1 / params.display_scale)
    set(gca, 'YDir', 'reverse')
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

% Overlap detection
p.addParameter('min_region_feats', 20);

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