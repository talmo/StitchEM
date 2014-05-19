%% Load pair of sections
% Assumes these already have Z alignment
s = 3;
secA = secs{s - 1};
secB = secs{s};

matches = secB.z_matches;

%% Visualize matches
figure
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'prev_z', 'g0.1')
plot_matches(matches.A, matches.B)
title(sprintf('Matches before alignment (secs %d <-> %d) | Error: %fpx / match', secA.num, secB.num, matches.meta.avg_error))
axis equal

figure
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'z', 'g0.1')
z_rel_tform = secB.alignments.z.rel_tforms{1}; % rel_tforms are the same for every time
plot_matches(matches.A, z_rel_tform.transformPointsForward(matches.B.global_points))
title(sprintf('Matches after alignment (secs %d <-> %d) | Error: %fpx / match', secA.num, secB.num, secB.alignments.z.meta.avg_post_error))
axis equal

tilefigs([],true,1,2,25,[],[],[],[0, 0],[1920, 1080])

%% Matches on first tile
idx = matches.A.tile == 1 & matches.B.tile == 1;
A1 = matches.A(idx, :);
B1 = matches.B(idx, :);

% Displacements
D1 = B1.global_points - A1.global_points;

%% Visualize
figure
plot_tile(secA, 1, 'z')
plot_tile(secB, 1, 'prev_z')
plot_matches(A1, B1)
title('Matches on tile 1')

figure
plot_displacements(D1)

%% Load tile images
tileA1 = imload_tile(secA.num, 1);
tileB1 = imload_tile(secB.num, 1);
disp('Loaded tiles.')

%% Improve accuracy with cpcorr
% this won't work because the tiles are rotated, need to apply tform first?
B1_local_corr = cpcorr2(B1.local_points, A1.local_points, tileB1, tileA1);

base_tformB = secB.alignments.prev_z.tforms{1};
B1_global_corr = base_tformB.transformPointsForward(B1_pts_corr);
prior_error = rownorm2(B1.global_points - A1.global_points);
post_error = rownorm2( - A1.global_points);

fprintf('cpcorr: %f -> %f px / match before alignment\n', prior_error, post_error)

tile1_matches.A = A1;
tile1_matches.B = B1;
tile1_matches.num_matches= height(A1);
tile1_matches.meta.alignmentB = 'prev_z';

tile1_matches_corr = tile1_matches;
tile1_matches_corr.B.local_points = B1_local_corr;
tile1_matches_corr.B.global_points = B1_global_corr;

non_corr_lsq = align_z_pair_lsq(secB, tile1_matches);
corr_lsq = align_z_pair_lsq(secB, tile1_matches_corr);

non_corr_cpd = align_z_pair_cpd(secB, tile1_matches);
corr_cpd = align_z_pair_cpd(secB, tile1_matches_corr);

%% Pick a single match to work with
i = 24;
matchA = A1(i, :);
matchB = B1(i, :);

% Displacement
D_prior = matchB.global_points - matchA.global_points;

%% Visualize
figure
plot_tile(secA, 1, 'z')
plot_tile(secB, 1, 'prev_z')
plot_matches(matchA, matchB)
title('Match on tile 1')

%% Extract image region around matches

