function match_stats = matching_stats(inliersA, inliersB, outliersA, outliersB)
%MATCHING_STATS Calculates statistics on set of matches.

match_stats.section_nums = sort(unique([unique(inliersA.section); unique(inliersB.section)]));
match_stats.num_sections = length(match_stats.section_nums);

match_stats.tile_nums = sort(unique([unique(inliersA.tile); unique(inliersB.tile)]));
match_stats.num_tiles = length(match_stats.tile_nums);

match_stats.num_inliers = size(inliersA, 1);
match_stats.num_outliers = size(outliersA, 1);

match_stats.inlier_dists = calculate_match_distances(inliersA, inliersB);
match_stats.outlier_dists = calculate_match_distances(outliersA, outliersB);

match_stats.tile_summary = table([], [], [], [], [], [], [], ...
    'VariableNames', {'tile_num', 'num_inliers', 'mean_inlier_dists', 'std_inlier_dists', 'num_outliers', 'mean_outlier_dists', 'std_outlier_dists'});

for t = 1:match_stats.num_tiles
    tile_num = match_stats.tile_nums(t);
    
    [tile_matchesA, tile_matchesB] = filter_matches(inliersA, inliersB, 'tile', tile_num);
    [tile_outliersA, tile_outliersB] = filter_matches(outliersA, outliersB, 'tile', tile_num);
    
    inlier_dists = calculate_match_distances(tile_matchesA, tile_matchesB);
    outlier_dists = calculate_match_distances(tile_outliersA, tile_outliersB);
    
    num_inliers = length(inlier_dists);
    num_outliers = length(outlier_dists);
    
    mean_inlier_dists = mean(inlier_dists);
    mean_outlier_dists = mean(outlier_dists);
    
    std_inlier_dists = std(inlier_dists);
    std_outlier_dists = std(outlier_dists);
    
    match_stats.tile(tile_num).inliers.A = tile_matchesA;
    match_stats.tile(tile_num).inliers.B = tile_matchesB;
    match_stats.tile(tile_num).outliers.A = tile_outliersA;
    match_stats.tile(tile_num).outliers.B = tile_outliersB;
    match_stats.tile(tile_num).inlier_dists = inlier_dists;
    match_stats.tile(tile_num).outlier_dists = outlier_dists;
    match_stats.tile(tile_num).num_inliers = num_inliers;
    match_stats.tile(tile_num).num_outliers = num_outliers;
    match_stats.tile(tile_num).mean_inlier_dists = mean_inlier_dists;
    match_stats.tile(tile_num).mean_outlier_dists = mean_outlier_dists;
    match_stats.tile(tile_num).std_inlier_dists = std_inlier_dists;
    match_stats.tile(tile_num).std_outlier_dists = std_outlier_dists;
    
    match_stats.tile_summary = [match_stats.tile_summary; ...
        table(tile_num, num_inliers, mean_inlier_dists, std_inlier_dists, num_outliers, mean_outlier_dists, std_outlier_dists)];
end




end

