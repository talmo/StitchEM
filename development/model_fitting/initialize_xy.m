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