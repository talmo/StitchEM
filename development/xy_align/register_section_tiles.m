sec_num = 100;

%% Initialize
% Load section images
sec = sec_struct(sec_num, 0.125);

% Register tiles to section overview
[sec.rough_alignments, sec.grid_aligned] = rough_align_tiles(sec);

%% Detect features
sec.features = detect_section_features(sec);

%% Match
%[matchesA, matchesB] = match_section_features(sec);
% TODO:
% - create match_section_features function to serve as a wrapper for
% match_feature_sets, similar to match_section_pair
% - add functionality to match_feature_sets for finding bounding regions
% based on pairwise tile overlaps

%% Rigidity curve
lambda_curve(matchesA, matchesB);

%% Align
sec = align_section_tiles(sec, matchesA, matchesB, 'lambda', 0.05);

%% Render
[merges, merges_R] = imshow_section(sec, 'tforms', 'fine', 'suppress_display', false);