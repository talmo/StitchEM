function z_matches = match_z_features(secA, featuresA, secB, featuresB, parameters)
%MATCH_Z_FEATURES Finds matching features across a pair of sections.

%% Process parameters
% Default parameters
params.NNR.MatchThreshold = 0.90;
params.NNR.MaxRatio = 0.7;
params.inlier.method = 'cluster';
params.inlier.GMClusters = 2;
params.inlier.GMReplicates = 5;

% TODO: Overwrite defaults with inputted parameters

%% Match across sections
matches = {}; % Stores the match sets
num_matches = 0; % Counter for matches found

% Loop through tiles
for i = 1:length(secA.tiles)
    % Get the features for this tile
    pointsA = featuresA(i).z.points;
    descriptorsA = featuresA(i).z.descriptors;
    
    % Get the features for the matching tile
    pointsB = featuresB(i).z.points;
    descriptorsB = featuresB(i).z.descriptors;
    
    % Adjust points to global coordinates
    pointsA = pointsA + ...
            [repmat(secA.tiles(i).x_offset, size(pointsA, 1), 1) ... % X offset
             repmat(secA.tiles(i).y_offset, size(pointsA, 1), 1)];   % Y offset
    pointsB = pointsB + ...
            [repmat(secB.tiles(i).x_offset, size(pointsB, 1), 1) ... % X offset
             repmat(secB.tiles(i).y_offset, size(pointsB, 1), 1)];   % Y offset
     
     % Match the features
    try
        match_idx = processing.match_features(pointsA, descriptorsA, ...
            pointsB, descriptorsB, params);
    catch
        warning('Failed to find matching features for %s (tile %d) and %s (tile %d).', secA.name, i, secB.name, i)
        continue
    end
    
    % Extract matched points from this tile
    match_set = struct();
    match_set.A.points = pointsA(match_idx(:, 1), :);
    match_set.A.section = secA.section_number;
    match_set.A.tile = i;
    match_set.A.type = 'z';

    % Extract matched points from matching tile
    match_set.B.points = pointsB(match_idx(:, 2), :);
    match_set.B.section = secB.section_number;
    match_set.B.tile = i;
    match_set.B.type = 'z';

    % Save to output structure
    matches{i} = match_set;
    
    % Increment matches counter
    num_matches = num_matches + size(match_set.A.points, 1);
end

% Remove empty cells
matches(cellfun(@isempty, matches)) = [];


%% Save matches to structure with metadata
z_matches.timestamp = datestr(now);
z_matches.parameters = params;
z_matches.num_matches = num_matches;
z_matches.matches = matches;

% Logging
msg = sprintf('Found %d Z matches between sections %s and %s.', num_matches, secA.name, secB.name);
fprintf('%s\n', msg)
stitch_log(msg, secA.data_path);

end

