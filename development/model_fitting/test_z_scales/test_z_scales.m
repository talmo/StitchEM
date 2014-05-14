% This script evaluates the performance of Z matching using features detected at different scales.

% Section numbers
A = 100;
B = 101;

%% Initialization
% Initializes the two sections by aligning in XY
initialize_xy

% Save results
results_file = sprintf('results_sec%d-%d.csv', A, B);
if exist(results_file)
    results = readtable(results_file);
else
    results = table();
end
%% Scale
z_scale = 0.35;

% Load tiles
secA = load_tileset(secA, 'z', z_scale);
secB = load_tileset(secB, 'z', z_scale);

%% Matching
z_SURF.MetricThreshold = 10000; % default = 1000
z_SURF.NumOctaves = 3; % default = 3
z_SURF.NumScaleLevels = 4; % default = 4
z_NNR.MatchThreshold = 1.0; % default = 1.0
z_NNR.MaxRatio = 0.6; % default = 0.6

% Detect features at particular scale
secA.features.z = detect_features(secA, 'regions', sec_bb(secB, 'xy'), 'alignment', 'xy', 'detection_scale', z_scale, z_SURF);
secB.features.z = detect_features(secB, 'regions', sec_bb(secA, 'xy'), 'alignment', 'xy', 'detection_scale', z_scale, z_SURF);

% Match features
z_matches = match_z(secA, secB, z_NNR);

% Match statistics
M = merge_match_sets(z_matches);
displacements = M.B.global_points - M.A.global_points;
global_median = geomedian(displacements);
[~, distances] = rownorm2(bsxadd(displacements, -global_median));

% Solve alignment
fprintf('== Aligning section %d to section %d\n', B, A)

% LSQ_tiles
try
    [secA.alignments.z_lsq_tiles, secB.alignments.z_lsq_tiles] = align_z_pair_lsq_tiles(secA, secB, z_matches);
    lsq_tiles_error = secB.alignments.z_lsq_tiles.meta.avg_post_error;
catch
    lsq_tiles_error = NaN;
end

% LSQ
secB.alignments.z_lsq = align_z_pair_lsq(secB, z_matches);

% CPD
secB.alignments.z_cpd = align_z_pair_cpd(secB, z_matches);

%% Save results
observation = table();
observation.scale = z_scale;
observation.MetricThreshold = z_SURF.MetricThreshold;
observation.num_matches = z_matches.num_matches;
observation.base = secB.alignments.z_lsq.meta.avg_prior_error;
observation.lsq_tiles = lsq_tiles_error;
observation.lsq = secB.alignments.z_lsq.meta.avg_post_error;
observation.cpd = secB.alignments.z_lsq.meta.avg_post_error;
results(end + 1, :) = observation;
writetable(results, results_file) % Save!
return
%% Visualize matches
% Plot sections and matches
figure
set(gcf, 'Position', [2324, 179, 919, 756])
plot_section(secA, 'xy')
plot_section(secB, 'xy')
plot_matches(M.A, M.B);
title(sprintf('Section %d <-> %d | Alignment: xy | n = %d matches | Detection scale = %sx', secA.num, secB.num, z_matches.num_matches, num2str(z_scale)))

%% Visualize alignment
figure
set(gcf, 'Position', [1947, 329, 1632, 470])
subaxis(1, 3, 1)
plot_section(secA, 'z_lsq_tiles')
plot_section(secB, 'z_lsq_tiles')
title(sprintf('\\bfLSQ\\_tiles\\rm | Error: %fpx/match', secB.alignments.z_lsq_tiles.meta.avg_post_error))

subaxis(1, 3, 2)
plot_section(secA, 'xy')
plot_section(secB, 'z_lsq')
title(sprintf('\\bfLSQ\\rm | Error: %fpx/match', secB.alignments.z_lsq.meta.avg_post_error))

subaxis(1, 3, 3)
plot_section(secA, 'xy')
plot_section(secB, 'z_cpd')
title(sprintf('\\bfCPD\\rm | Error: %fpx/match', secB.alignments.z_cpd.meta.avg_post_error))

fig_title = sprintf('Section %d <-> %d | n = %d matches | Detection scale = %sx', secA.num, secB.num, z_matches.num_matches, num2str(z_scale));
annotation('textbox', [0 0.9 1 0.1], 'String', fig_title, 'EdgeColor', 'none', 'HorizontalAlignment', 'center')


%% Visualize LSQ vs CPD
figure
set(gcf, 'Position', [2079, 228, 1378, 578])
subaxis(1, 2, 1)
plot_section(secA, 'xy')
plot_section(secB, 'z_lsq')
title(sprintf('\\bfLSQ\\rm | Error: %fpx/match', secB.alignments.z_lsq.meta.avg_post_error))

subaxis(1, 2, 2)
plot_section(secA, 'xy')
plot_section(secB, 'z_cpd')
title(sprintf('\\bfCPD\\rm | Error: %fpx/match', secB.alignments.z_cpd.meta.avg_post_error))

fig_title = sprintf('Section %d <-> %d | n = %d matches | Detection scale = %sx', secA.num, secB.num, z_matches.num_matches, num2str(z_scale));
annotation('textbox', [0 0.9 1 0.1], 'String', fig_title, 'EdgeColor', 'none', 'HorizontalAlignment', 'center')
