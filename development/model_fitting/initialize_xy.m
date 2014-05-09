% Initialize and XY align two sections

initialize_xy_time = tic;

xy_SURF.MetricThreshold = 11000;

% Load sections
scales = {'full', 1.0, 'rough', 0.07 * 0.78};
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

% Clear tile images
for s = fieldnames(secA.tiles)'; secA = clear_tileset(secA, s{1}); end
for s = fieldnames(secB.tiles)'; secB = clear_tileset(secB, s{1}); end

fprintf('==== Finished XY initialization in %.2fs.\n', toc(initialize_xy_time));
clear initialize_xy_time s scales xy_SURF