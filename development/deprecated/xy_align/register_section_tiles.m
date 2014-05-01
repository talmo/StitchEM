sec_num = 100;

%% Initialize
% Load section images
sec = sec_struct(sec_num, 0.78 * 0.07);

% Register tiles to section overview
[sec.rough_alignments, sec.grid_aligned] = rough_align_tiles(sec);

%% Detect features
sec.features = detect_section_features(sec, 'MetricThreshold', 11000);

%% Match
[matchesA, matchesB] = match_section_features(sec, 'show_matches', true, ...
    'MatchThreshold', 0.2, 'MaxRatio', 0.6);

%% Rigidity curve
lambda_curve(matchesA, matchesB);

%% Align
sec = align_section_tiles(sec, matchesA, matchesB, 'lambda', 0.05);

%% Render
[merges, merges_R] = imshow_section(sec, 'tforms', 'fine', 'suppress_display', false);