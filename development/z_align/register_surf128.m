sec_num = 100;

% Load images
secA = sec_struct(sec_num);
secB = sec_struct(sec_num + 1);

%% Initialize and detect features
[secA, secB] = initialize_section_pair(secA, secB, 'overwrite_features', true, 'SURFSize', 128, 'MetricThreshold', 1000);

%% Match
[matchesAB, matchesBA] = match_section_pair(secA, secB, 'show_matches', true, 'show_regions', true, 'MatchThreshold', 1.0, 'MaxRatio', 0.9, 'filter_inliers', false);

% Align
[secA, secB, mean_error] = align_section_pair(secA, secB, matchesAB, matchesBA, 'lambda', 0.005, 'show_summary', true, 'show_merge', false);