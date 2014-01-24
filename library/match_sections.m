function matching_points = match_sections(secA, secB, parameters)
%MATCH_SECTIONS Finds matching points between all tiles across two 
% different sections.
% Takes two section structures returned from initialize_section.

%% Parameters
params.scaling.resolution = 2000;

% Overwrite defaults with any parameters passed in
if nargin >= 3
    f = fieldnames(parameters); % fields
    for i = 1:length(f)
        sf = fieldnames(parameters.(f{i})); % subfields
        for e = 1:length(sf)
            params.(f{i}).(sf{e}) = parameters.(f{i}).(sf{e});
        end
    end
end

%% Find matches
total_timer = tic;
fprintf('Finding matches between %s and %s...\n', secA.name, secB.name)

% The two sections have the same number of tiles
num_tiles = min(numel(secA.tiles), numel(secB.tiles));

% Tiles should be square
scaling_factor = params.scaling.resolution / secA.tiles(1).width;

% Pre-allocate cell array for holding the matching points
matching_points = cell(num_tiles, 1);

% Find matches in each tile pair
matches_found = zeros(num_tiles, 1);
parfor t = 1:num_tiles
    fprintf('  Matching tile pair %d...', t), tic;
    
    % Load tile images and resize
    tileA = imresize(imread(secA.tiles(t).path), scaling_factor);
    tileB = imresize(imread(secB.tiles(t).path), scaling_factor);
    
    % Find features in each image
    [ptsA, descA] = find_features(tileA);
    [ptsB, descB] = find_features(tileB);
    
    % Match features between images
    matches = match_features(ptsA, descA, ptsB, descB);
    
    % Get matched points
    matched_pointsA = ptsA(matches(:, 1), :);
    matched_pointsB = ptsB(matches(:, 2), :);
    
    % Keep track of how many matches we've found
    matches_found(t) = size(matched_pointsA, 1);
    
    % Rescale points to original resolution
    matched_pointsA = matched_pointsA * (1 / scaling_factor);
    matched_pointsB = matched_pointsB * (1 / scaling_factor);
    
    % Adjust coordinates to grid position
    matched_pointsA = matched_pointsA + ...
        repmat([secA.tiles(t).x_offset secA.tiles(t).y_offset], ...
               [matches_found(t) 1]);
    matched_pointsB = matched_pointsB + ...
        repmat([secB.tiles(t).x_offset secB.tiles(t).y_offset], ...
               [matches_found(t) 1]);
    
    % Save to cell array of matches
    matching_points{t} = {matched_pointsA, matched_pointsB};
    
    fprintf(' Found %d matches in %.2fs.\n', matches_found(t), toc)
end

fprintf('Done matching both sections.\n  Found %d matches in %.2fs.\n', ...
    sum(matches_found), toc(total_timer))

end

