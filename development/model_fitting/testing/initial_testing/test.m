%% Initialization
% Load images and such
secA = load_sec(100, 'from_cache', false);
secB = load_sec(101, 'from_cache', false);

%% Rough alignment
% Register the overviews
secB.overview_tform = register_overviews(secB, secA);

% Register the tiles to their overviews
secA = rough_align_tiles(secA);
secB = rough_align_tiles(secB);

%% Detect features
% Get overlap regions
% find_overlaps(secA, secB) % z overlaps
% find_overlaps(secA, secA) % xy overlaps

% Detect features in regions
% detect_section_features(sec, regions, scale) % will detect features at the given scale, in any parts of the tiles that overlap with the input regions

secA = detect_section_features(secA);
secB = detect_section_features(secB);

%% Match XY features
[xy_matchesA.A, xy_matchesA.B] = match_section_features(secA);
[xy_matchesB.A, xy_matchesB.B] = match_section_features(secB);

%% Solve XY alignment
% Build matrices
[A, B] = matchmat(xy_matchesA.A, xy_matchesA.B);
b = matchmat2vec(B);

% Deal with fixed tile
fixed_tile = 1;
%...

%% Find Z matches
[z_matches.A, z_matches.B] = match_section_pair(secA, secB, 'filter_inliers', false);

tile1_matchesA = z_matches.A(z_matches.A.tile == 1 & z_matches.B.tile == 1, :);
tile1_matchesB = z_matches.B(z_matches.A.tile == 1 & z_matches.B.tile == 1, :);
displacements = tile1_matchesB.global_points - tile1_matchesA.global_points;

%% Visualize displacements
figure
title('Displacements'), grid on
scatter(displacements(:,1), displacements(:,2), 'x')

%% Outliers vs inliers
Z = linkage(displacements, 'single', 'mahalanobis');
figure
dendrogram(Z)
title('Hierarchy of clusters of displacements')

figure
%T = cluster(Z, 'maxclust', 2);
%T = cluster(Z, 'cutoff', c, 'depth', d);
T = cluster(Z, 'cutoff', 0.2, 'criterion', 'distance');
scatter(displacements(:,1), displacements(:,2), 36, T, 'x')
grid on, title('Inliers cluster')



% Now see how they fit to a model?