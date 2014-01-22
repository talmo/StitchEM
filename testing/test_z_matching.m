% This script compares different methods of feature matching across
% sections. Primarily, we're trying to see if resizing the image ahead of
% time will serve to increase cross-section matching accuracy.

%% Load things
% Load sections
secA = initialize_section('/data/home/talmo/EMdata/W002/S2-W002_Sec100_Montage');
secB = initialize_section('/data/home/talmo/EMdata/W002/S2-W002_Sec101_Montage');

% Load images
tileA = imread(secA.tiles(1).path);
tileB = imread(secB.tiles(1).path);

%% Resize
tileA_small = imresize(tileA, 0.25);
tileB_small = imresize(tileB, 0.25);

%% Find features
[ptsA, descA] = find_features(tileA, 'surf');
[ptsB, descB] = find_features(tileB, 'surf');
[ptsA_small, descA_small] = find_features(tileA_small, 'surf');
[ptsB_small, descB_small] = find_features(tileB_small, 'surf');

%% Match features
matches = match_features(ptsA, descA, ptsB, descB);
matches_small = match_features(ptsA_small, descA_small, ptsB_small, descB_small);

%% Plot matches
plot_matches(ptsA_small(matches_small(:, 1)), ptsB_small(matches_small(:, 2)));
plot_matches(ptsA_small(matches_small(:, 1)), ptsB_small(matches_small(:, 2)));