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
title('Matches on tile 1')

%% Extract image region around matches

