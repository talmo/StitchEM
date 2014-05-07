% This script evaluates the performance of Z matching using features detected at different scales.
A = 103;
B = 104;
scales = {'full', 1.0, 'half', 0.5, 'rough', 0.07 * 0.78};

%% Initialize and XY align
xy_SURF.MetricThreshold = 11000;

% Load sections
secA = load_section(A, 'scales', scales);
secB = load_section(B, 'scales', scales);

% Register overview of section B to A
secB.overview.alignment = align_overviews(secA, secB);

% Rough alignment
secA.alignments.rough = rough_align(secA);
secB.alignments.rough = rough_align(secB);

% Detect XY features
secA.features.xy = detect_features(secA, 'regions', 'xy', xy_SURF);
secB.features.xy = detect_features(secB, 'regions', 'xy', xy_SURF);

% Match XY features
secA.xy_matches = match_xy(secA);
secB.xy_matches = match_xy(secB);

% Align XY
secA.alignments.xy = align_xy(secA);
secB.alignments.xy = align_xy(secB);

%% Z Alignment
z_scale = 0.25;
z_SURF.MetricThreshold = 5000; % default = 1000
z_SURF.NumOctaves = 3; % default = 3
z_SURF.NumScaleLevels = 4; % default = 4
z_NNR.MatchThreshold = 1.0; % default = 1.0
z_NNR.MaxRatio = 0.6; % default = 0.6

% Detect features at particular scale
secA.features.z = detect_features(secA, 'regions', sec_bb(secB, 'xy'), 'detection_scale', z_scale, z_SURF);
secB.features.z = detect_features(secB, 'regions', sec_bb(secA, 'xy'), 'detection_scale', z_scale, z_SURF);

% Match features
z_matches = match_z(secA, secB, z_NNR);

%% Evaluate results
