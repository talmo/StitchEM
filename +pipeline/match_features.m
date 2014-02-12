function [xy_matches, z_matches] = match_features(sections, parameters)
%FIND_MATCHING_FEATURES Matches things!
 
%% Parameters
params.z_matches_path = '..';

% Overwrite defaults with any parameters passed in
% TODO

%% Find matching features
xy_matches = {};
z_matches = struct();

for s = 1:length(sections)
    section = sections{s};
    
    % Load features from cache
    if exist([section.path filesep 'stitch_features.mat'], 'file')
        cache = load([section.path filesep 'stitch_features.mat'], 'features');
        feats(s) = cache.features;
    else
        warning(['Features not found for %s. '...
            'No matching will be done for this section.\n' ...
            'Use find_section_features() to detect features first.\n'], section.name);
    end
    
    % XY feature matching
    if isfield(feats(s), 'features') && (params.overwrite || ~exists([section.path filesep 'stitch_matches.mat']))
        % Initialize match look-up index and match-set container
        matches.index(section.num_tiles) = struct();
        matches.sets = {};

        % Find matches per tile
        for tA = 1:length(section.tiles)
            tile = section.tiles(tA);
            
            % Get list of seams in this tile
            seam_names = fieldnames(tile.seams);
            for i = 1:length(seam_names)
                seam_nameA = seam_names{i};
                
                % Check if we've already matched this seam
                if ~isfield(matches.index(tA), seam_nameA)
                    % Get matching tile info
                    tB = tile.seams.(seam_nameA).matching_tile;
                    seam_nameB = tile.seams.(seam_nameA).matching_seam;
                    
                    % Get relevant data from loaded features
                    ptsA = feats(s).features(tA).(seam_nameA).points;
                    ptsB = feats(s).features(tB).(seam_nameB).points;
                    descA = feats(s).features(tA).(seam_nameA).descriptors;
                    descB = feats(s).features(tB).(seam_nameB).descriptors;
                    
                    % Find matching features
                    matching_feats = match_features(ptsA, descA, ptsB, descB);
                    
                    % Save match set
                    matches.sets{end + 1} = {matching_feats(:, 1), matching_feats(:, 2)};
                    
                    % Save to index
                    matches.index(tA).(seam_nameA) = length(matches.sets);
                    matches.index(tB).(seam_nameB) = length(matches.sets);
                end
            end
        end

        % Save matches
        save([section.path filesep 'stitch_matches.mat'], matches);
        
        % Save to list of section matches
        xy_matches{s} = matches;
    end
end

%% Find Z matches across sections
z_matches = struct();


%% Find matches
% total_timer = tic;
% fprintf('Finding matches between %s and %s...\n', secA.name, secB.name)
% 
% % The two sections have the same number of tiles
% num_tiles = min(secA.num_tiles, secB.num_tiles);
% 
% % Tiles should be square
% scaling_factor = params.scaling.resolution / secA.tiles(1).width;
% 
% % Pre-allocate cell array for holding the matching points
% matching_points = cell(num_tiles, 1);
% 
% % Find matches in each tile pair
% matches_found = zeros(num_tiles, 1);
% for t = 1:num_tiles
%     fprintf('  Matching tile pair %d...', t), tic;
%     
%     % Load tile images and resize
%     tileA = imresize(imread(secA.tiles(t).path), scaling_factor);
%     tileB = imresize(imread(secB.tiles(t).path), scaling_factor);
%     
%     % Find features in each image
%     [ptsA, descA] = find_features(tileA);
%     [ptsB, descB] = find_features(tileB);
%     
%     % Match features between images
%     matches = match_features(ptsA, descA, ptsB, descB);
%     
%     % Get matched points
%     matched_pointsA = ptsA(matches(:, 1), :);
%     matched_pointsB = ptsB(matches(:, 2), :);
%     
%     % Keep track of how many matches we've found
%     matches_found(t) = size(matched_pointsA, 1);
%     
%     % Rescale points to original resolution
%     matched_pointsA = matched_pointsA * (1 / scaling_factor);
%     matched_pointsB = matched_pointsB * (1 / scaling_factor);
%     
%     % Adjust coordinates to grid position
%     matched_pointsA = matched_pointsA + ...
%         repmat([secA.tiles(t).x_offset secA.tiles(t).y_offset], ...
%                [matches_found(t) 1]);
%     matched_pointsB = matched_pointsB + ...
%         repmat([secB.tiles(t).x_offset secB.tiles(t).y_offset], ...
%                [matches_found(t) 1]);
%     
%     % Save to cell array of matches
%     matching_points{t} = {matched_pointsA, matched_pointsB};
%     
%     fprintf(' Found %d matches in %.2fs.\n', matches_found(t), toc)
% end
% 
% fprintf('Done matching both sections.\n  Found %d matches in %.2fs.\n', ...
%     sum(matches_found), toc(total_timer))

end

