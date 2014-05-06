% This script evaluates the performance of Z matching using features detected at different scales.
A = 103;
B = 104;
scales = {'full', 1.0, 'half', 0.5, 'rough', 0.07 * 0.78};

%% Initialize
% Load sections
secA = load_section(A, 'scales', scales);
secB = load_section(B, 'scales', scales);

% Register overview of section B to A
secB.overview.alignment = align_overviews(secA, secB);

% Rough alignment
secA.alignments.rough = rough_align(secA);
secB.alignments.rough = rough_align(secB);

% Detect XY features
secA.features.xy = detect_features(secA, 'regions', 'xy');
secB.features.xy = detect_features(secB, 'regions', 'xy');

% Match XY features
secA.xy_matches = match_xy(secA);
secB.xy_matches = match_xy(secB);

% Align XY
secA.alignments.xy = align_xy(secA);
secB.alignments.xy = align_xy(secB);

%% Z Alignment
z_scale = 0.125;

% Detect features at particular scale
secA.features.z = detect_features(secA, 'regions', sec_bb(secB, 'xy'), 'detection_scale', z_scale);
secB.features.z = detect_features(secB, 'regions', sec_bb(secA, 'xy'), 'detection_scale', z_scale);

% Match features
z_matches = match_z(secA, secB);

%% Evaluate results
