function matches = match_z(secA, secB, varargin)
%MATCH_Z Finds Z matches betwen two sections.
% Usage:
%   z_matches = match_z(secA, secB)

% Process parameters
[params, unmatched_params] = parse_input(varargin{:});

if params.verbosity > 0; fprintf('== Matching Z features between sections %d and %d.\n', secA.num, secB.num); end
total_time = tic;

% Feature sets
featuresA = secA.features.(params.feature_set);
featuresB = secB.features.(params.feature_set);

% Find matches between pairs of tiles
match_sets = {};
match_idx = cell(secA.num_tiles, secB.num_tiles);
num_matches = 0;
for tA = 1:secA.num_tiles
    % Get tile features
    tile_featsA = featuresA.tiles{tA};
    
    % Match with each tile it overlaps with
    overlapping_tiles = featuresA.meta.overlap_with{tA};
    for tB = overlapping_tiles
        % Get matching tile features
        tile_featsB = featuresB.tiles{tB};
        
        % Find the region numbers of the overlap between the two tiles
        regionA = find(featuresA.meta.overlap_with{tA} == tB, 1);
        regionB = find(featuresB.meta.overlap_with{tB} == tA, 1);
        
        % Get only the features in these regions
        region_featsA = tile_featsA(tile_featsA.region == regionA, :);
        region_featsB = tile_featsB(tile_featsB.region == regionB, :);
        
        % Skip if either has no features
        if isempty(region_featsA) || isempty(region_featsB)
            continue
        end
        
        % Match using Nearest-Neighbor Ratio
        match_set = nnr_match(region_featsA, region_featsB, unmatched_params);
        
        % Skip if we didn't find any matches
        if isempty(match_set.A)
            continue
        end
        
        % Filter based on distance from median
        if params.filter_outliers
            displacements = region_featsB.global_points(match_set.B, :) ...
                          - region_featsA.global_points(match_set.A, :);
            [inliers, outliers] = geomedfilter(displacements);
            
            match_set.A = match_set.A(inliers);
            match_set.B = match_set.B(inliers);
            match_set.metric = match_set.metric(inliers);
            match_set.meta.num_inliers = length(inliers);
            match_set.meta.num_outliers = length(outliers);
        end
        
        % Skip if we filtered out all the matches
        if isempty(match_set.A)
            continue
        end
        
        % Get table data from matched indices
        match_set.A = region_featsA(match_set.A, params.keep_cols);
        match_set.B = region_featsB(match_set.B, params.keep_cols);
        
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

% Second pass of filtering
if params.filter_secondpass
    % Reset global match counter
    num_matches = 0;
    
    % Combine all matches
    all_matches.A = cell2mat(cellfun(@(m) m.A.global_points, match_sets, 'UniformOutput', false));
    all_matches.B = cell2mat(cellfun(@(m) m.B.global_points, match_sets, 'UniformOutput', false));
    
    % Calculate displacements
    all_displacements = all_matches.B - all_matches.A;
    
    % Get the global geometric median of displacements
    global_median = geomedian(all_displacements);
    
    % Compute global threshold
    [~, all_distances] = rownorm2(bsxadd(all_displacements, -global_median));
    global_thresh = median(all_distances) * 3;
    
    % Re-filter match sets
    for i = 1:length(match_sets)
        displacements = match_sets{i}.B.global_points - match_sets{i}.A.global_points;
        [inliers, outliers] = geomedfilter(displacements, global_median, 'threshold', global_thresh);
        
        % Update inliers
        match_sets{i}.A = match_sets{i}.A(inliers, :);
        match_sets{i}.B = match_sets{i}.B(inliers, :);
        match_sets{i}.metric = match_sets{i}.metric(inliers);
        
        % Metadata
        match_sets{i}.meta.num_inliers = length(inliers);
        match_sets{i}.meta.num_outliers = match_sets{i}.meta.num_outliers + length(outliers);
        
        % Update match counters
        match_sets{i}.num_matches = length(inliers);
        num_matches = num_matches + length(inliers);
    end
end

% Save to output structure
matches.match_sets = match_sets;
matches.tile_idx = match_idx;
matches.secA = secA.num;
matches.secB = secB.num;
matches.feature_set = params.feature_set;
matches.num_matches = num_matches;
matches.meta.unmatched_params = unmatched_params;

if params.verbosity > 0; fprintf('Found %d matches. [%.2fs]\n', num_matches, toc(total_time)); end

end

function [params, unmatched] = parse_input(varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Feature set
p.addParameter('feature_set', 'z');

% Filter outliers
p.addParameter('filter_outliers', true);
p.addParameter('filter_secondpass', true);

% Columns to keep for the matched features
p.addParameter('keep_cols', {'local_points', 'global_points'});

% Verbosity
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;

end