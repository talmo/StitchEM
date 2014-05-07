% This script evaluates the performance of Z matching using features detected at different scales.
% Note: Run initialize_xy first
secA = clear_tileset(secA, 'full');
secB = clear_tileset(secB, 'full');

%% Z Alignment
z_scale = 0.50;
z_SURF.MetricThreshold = 12000; % default = 1000
z_SURF.NumOctaves = 3; % default = 3
z_SURF.NumScaleLevels = 10; % default = 4
z_NNR.MatchThreshold = 1.0; % default = 1.0
z_NNR.MaxRatio = 0.6; % default = 0.6

% Detect features at particular scale
secA.features.z = detect_features(secA, 'regions', sec_bb(secB, 'xy'), 'detection_scale', z_scale, z_SURF);
secB.features.z = detect_features(secB, 'regions', sec_bb(secA, 'xy'), 'detection_scale', z_scale, z_SURF);

% Match features
z_matches = match_z(secA, secB, z_NNR);

%% Match statistics
M = merge_match_sets(z_matches);
displacements = M.B.global_points - M.A.global_points;
global_median = geomedian(displacements);
[~, distances] = rownorm2(bsxadd(displacements, -global_median));

%% Visualize
% Plot sections and matches
plot_section(secA, 'xy')
plot_section(secB, 'xy')
plot_matches(M.A, M.B);
title(sprintf('Section %d <-> %d | Alignment: xy | n = %d matches | Detection scale = %sx', secA.num, secB.num, z_matches.num_matches, num2str(z_scale)))

%% Solve using least squares
[secA.alignments.z, secB.alignments.z] = align_z_pair(secA, secB, z_matches);
plot_section(secA, 'z')
plot_section(secB, 'z')

%% Solve using CPD
cpd_solve(z_matches)