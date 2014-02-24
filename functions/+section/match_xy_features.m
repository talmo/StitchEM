function xy_matches = match_xy_features(sec, features, parameters)
%MATCH_XY_FEATURES Finds matching features in the seams between the tiles of a section.

%% Process parameters
% Default parameters
params.overwrite = false;
params.NNR.Method = 'NearestNeighborRatio';
params.NNR.Metric = 'SSD';
params.NNR.MatchThreshold = 0.2;
params.NNR.MaxRatio = 0.7;
params.inlier.method = 'none';

% TODO: handle custom parameters
%params = parameters;

%% Check for cache
% Load from cached file
if exist(sec.xy_matches_path, 'file') && ~params.overwrite
    xy_matches = section.load_xy_matches(sec);
    return
end

%% Match features in seams
matches = {}; % Stores the actual match structures
matched_seams = {}; % Keeps track of seams already matched
num_matches = 0; % Counter for total matches found

% Loop through tiles
for i = 1:length(sec.tiles)
    % Loop through seams
    for s = fieldnames(sec.tiles(i).seams)'
        % Get seam info
        seam_name = s{1};
        seam = sec.tiles(i).seams.(seam_name);
        
        % Check if we've matched this seam or the matching seam before
        if any(cellfun(@(c) isequal(c, {i, seam_name}), matched_seams)) || ...
                any(cellfun(@(c) isequal(c, {seam.matching_tile, seam.matching_seam}), matched_seams))
            continue % Skip this seam
        end
        
        % Get features from this seam
        pointsA = features(i).xy.(seam_name).points;
        descriptorsA = features(i).xy.(seam_name).descriptors;
        
        % Get features from matching seam
        pointsB = features(seam.matching_tile).xy.(seam.matching_seam).points;
        descriptorsB = features(seam.matching_tile).xy.(seam.matching_seam).descriptors;
        
        % Adjust points to global coordinates
        pointsA = pointsA + ...
                [repmat(sec.tiles(i).x_offset, size(pointsA, 1), 1) ... % X offset
                 repmat(sec.tiles(i).y_offset, size(pointsA, 1), 1)];   % Y offset
        pointsB = pointsB + ...
                [repmat(sec.tiles(seam.matching_tile).x_offset, size(pointsB, 1), 1) ... % X offset
                 repmat(sec.tiles(seam.matching_tile).y_offset, size(pointsB, 1), 1)];   % Y offset
        
        % Match the features
        match_idx = processing.match_features(pointsA, descriptorsA, ...
            pointsB, descriptorsB, params);
        
        % Extract matched points from this seam
        match_set = struct();
        match_set.A.points = pointsA(match_idx(:, 1), :);
        match_set.A.section = sec.section_number;
        match_set.A.tile = i;
        match_set.A.type = 'xy';
        match_set.A.seam_name = seam_name;
        
        % Extract matched points from matching seam
        match_set.B.points = pointsB(match_idx(:, 2), :);
        match_set.B.section = sec.section_number;
        match_set.B.tile = seam.matching_tile;
        match_set.B.type = 'xy';
        match_set.B.seam_name = seam.matching_seam;
        
        % Save to output structure
        matches{end + 1} = match_set;
        
        % Keep track of matched seams to avoid duplicates
        matched_seams{end + 1} = {i, seam_name};
        matched_seams{end + 1} = {seam.matching_tile, seam.matching_seam};
        
        % Increment matches counter
        num_matches = num_matches + size(match_set.A.points, 1);
    end
end

%% Save matches
% Build structure with metadata
xy_matches.timestamp = datestr(now);
xy_matches.parameters = params;
xy_matches.num_matches = num_matches;
xy_matches.matches = matches;

% Save to cache
save(sec.xy_matches_path, 'xy_matches')

% Logging
msg = sprintf('Found and saved %d XY matches for %s.', num_matches, sec.name);
fprintf('%s\n', msg)
stitch_log(msg, sec.data_path);

end

