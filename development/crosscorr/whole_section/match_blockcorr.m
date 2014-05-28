function matches = match_blockcorr(secA, secB)
%MATCH_BLOCKCORR Returns matches from block correlation of two sections.

%% Parameters
grid_sz = 2000;
block_sz = 150;
search_sz = 75; % around block
clahe_filter = true;
alignmentA = 'blockcorr';
alignmentB = 'z';

%% Figure out block grid
fprintf('== Matching %s and %s by block correlation.\n', secA.name, secB.name)
% Calculate intersections
bbA = sec_bb(secA, 'z');
bbB = sec_bb(secB, 'z');
[I, idx] = intersect_poly_sets(bbA, bbB);

% Filter to just where tA == tB (assumes tiles are overlapping)
diag_idx = [idx{sub2ind(size(idx), 1:size(idx, 1), 1:size(idx, 2))}];
tileI = I(diag_idx);

% Figure out world extents
bbWorld = minaabb(vertcat(tileI{:}));
[WorldXLims, WorldYLims] = bb2lims(bbWorld);

% Make grid
[gridX, gridY] = meshgrid(WorldXLims(1):grid_sz:WorldXLims(2), WorldYLims(1):grid_sz:WorldYLims(2));

% Create blocks and search regions
blocks = arrayfun(@(x, y) rect2bb(x, y, block_sz), gridX, gridY, 'UniformOutput', false);
search_regions = arrayfun(@(x, y) rect2bb(x - search_sz, y - search_sz, 2 * search_sz + block_sz), gridX, gridY, 'UniformOutput', false);

% Eliminate any that intersect with tile bounds
%all_valid = cellfun(@(rI) any(cellfun(@(tI) all(inpolygon(rI(:,1), rI(:,2), tI(:,1), tI(:,2))), tileI)), search_regions);
%all_valid_blocks = blocks(all_valid);
%all_valid_search_regions = search_regions(all_valid);

%% Matching
matching_timer = tic;

% Spatial refs
secA_tileRs = sec_refs(secA, alignmentA);
secB_tileRs = sec_refs(secB, alignmentB);

% Containers
pair_matchesA = cell(secA.num_tiles, 1);
pair_matchesB = cell(secA.num_tiles, 1);
parfor tA = 1:secA.num_tiles
    % Tile image
    tileA = imload_tile(secA, tA);
    if clahe_filter; tileA = adapthisteq(tileA); end
    tformA = secA.alignments.z.tforms{tA};
    RA = secA_tileRs{tA};
    tileA = imwarp(tileA, tformA, 'OutputView', RA, 'FillValues', mean(tileA(:)));
    
    tile_matchesA = cell(secB.num_tiles, 1);
    tile_matchesB = cell(secB.num_tiles, 1);
    for tB = 1:secB.num_tiles
        % Get the intersect of tile pair
        tI = intersect_polys(bbA{tA}, bbB{tB});
        
        % Skip to next tile pair if they don't overlap
        if isempty(tI); continue; end
        
        % Find search blocks completely contained in the intersect of the tiles
        valid_regions = cellfun(@(rI) all(inpolygon(rI(:,1), rI(:,2), tI(:,1), tI(:,2))), search_regions);
        
        % Skip to next tile pair if we don't have any valid blocks
        if ~any(valid_regions(:)); continue; end
        
        % Get valid blocks
        valid_blocks = blocks(valid_regions);
        valid_search_regions = search_regions(valid_regions);
        num_valid_blocks = numel(valid_blocks);
        
        %fprintf('tA = %d <-> tB = %d | n = %d blocks\n', tA, tB, num_valid_blocks)
        
        % Tile image
        tileB = imload_tile(secB, tB);
        if clahe_filter; tileB = adapthisteq(tileB); end
        tformB = secB.alignments.z.tforms{tB};
        RB = secB_tileRs{tB};
        tileB = imwarp(tileB, tformB, 'OutputView', RB, 'FillValues', mean(tileB(:)));
        
        % Match each block
        ptsA = cell(num_valid_blocks, 1);
        ptsB = cell(num_valid_blocks, 1);
        for i = 1:num_valid_blocks
            % Block and search area limits
            [XLimsA, YLimsA] = bb2lims(valid_search_regions{i});
            [XLimsB, YLimsB] = bb2lims(valid_blocks{i});

            % Convert to coordinates
            [searchI, searchJ] = RA.worldToSubscript(XLimsA, YLimsA);
            [blockI, blockJ] = RB.worldToSubscript(XLimsB, YLimsB);

            % Get image data
            search_region = tileA(searchI(1):searchI(2)-1, searchJ(1):searchJ(2)-1);
            block = tileB(blockI(1):blockI(2)-1, blockJ(1):blockJ(2)-1);
            
            % World locations
            locA = [XLimsA(1), YLimsA(1)];
            locB = [XLimsB(1), YLimsB(1)];
            
            % Cross correlation
            [ptA, ptB] = find_xcorr(search_region, locA, block, locB);
            
            % Save
            ptsA{i} = ptA;
            ptsB{i} = ptB;
        end
        
        % Merge points into matrix
        ptsA = vertcat(ptsA{:});
        ptsB = vertcat(ptsB{:});
        
        % Create match tables
        matchesA = table();
        matchesA.local_points = tformA.transformPointsInverse(ptsA);
        matchesA.global_points = ptsA;
        matchesA.tile = repmat(tA, size(ptsA, 1), 1);
        
        matchesB = table();
        matchesB.local_points = tformB.transformPointsInverse(ptsB);
        matchesB.global_points = ptsB;
        matchesB.tile = repmat(tB, size(ptsB, 1), 1);
        
        % Save
        tile_matchesA{tB} = matchesA;
        tile_matchesB{tB} = matchesB;
    end
    % Merge and save
    pair_matchesA{tA} = vertcat(tile_matchesA{:});
    pair_matchesB{tA} = vertcat(tile_matchesB{:});
end

% Merge match sets
matches.A = vertcat(pair_matchesA{:});
matches.B = vertcat(pair_matchesB{:});

% Get metrics before filtering
num_total_matches = height(matches.A);
avg_total_error = rownorm2(matches.B.global_points - matches.A.global_points);

% Filter
[inliers, outliers] = gmm_filter(matches, 'inlier_cluster', 'geomedian');

% Separate outliers and inliers
matches.outliers.A = matches.A(outliers, :);
matches.outliers.B = matches.B(outliers, :);
matches.A = matches.A(inliers, :); 
matches.B = matches.B(inliers, :);

% Calculate errors
avg_error = rownorm2(matches.B.global_points - matches.A.global_points);
avg_outlier_error = rownorm2(matches.outliers.B.global_points - matches.outliers.A.global_points);

% Add metadata
matches.num_matches = height(matches.A);
matches.meta.avg_error = avg_error;
matches.meta.avg_outlier_error = avg_outlier_error;
matches.meta.avg_total_error = avg_total_error;
matches.meta.num_outliers = height(matches.outliers.A);
matches.meta.num_total_matches = num_total_matches;
matches.meta.runtime = toc(matching_timer);

fprintf('Finished matching in <strong>%.2fs</strong> (<strong>%.2fs/block</strong>).\n', matches.meta.runtime, matches.meta.runtime / matches.meta.num_total_matches)
fprintf('Before filtering: %f px/match (n = %d)\n', matches.meta.avg_total_error, matches.meta.num_total_matches)
fprintf('After filtering: <strong>%f px/match (n = %d)</strong>\n', matches.meta.avg_error, matches.num_matches)


end

