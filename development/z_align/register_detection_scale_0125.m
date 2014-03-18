sec_num = 100;

% Load images
secA = sec_struct(sec_num, 0.125);
secB = sec_struct(sec_num + 1, 0.125);

%% Initialize and detect features
[secA, secB] = initialize_section_pair(secA, secB, 'overwrite_features', true, 'SURFSize', 64, 'MetricThreshold', 1000, 'detection_scale', 0.125);

%% Match
[matchesAB, matchesBA] = match_section_pair(secA, secB, 'show_matches', true, 'show_regions', false, 'show_stats', true, 'MatchThreshold', 1.0, 'MaxRatio', 0.7, 'filter_inliers', true);

%% Lambda curve
lambda_curve(matchesAB, matchesBA);

%% Align
[secA, secB, mean_error] = align_section_pair(secA, secB, matchesAB, matchesBA, 'lambda', 0.05, 'show_summary', true, 'show_merge', true, 'show_matches', false);

%% Inspect individual tile
i = 14;
imshow_tile_pair(secA.img.tiles{i}, secB.img.tiles{i}, secA.fine_alignments{i}, secB.fine_alignments{i})