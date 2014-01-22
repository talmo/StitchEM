% This script compares different methods of feature matching across
% sections. Primarily, we're trying to see if resizing the image ahead of
% time will serve to increase cross-section matching accuracy.

%% Load things
% Load sections
secA = initialize_section('/data/home/talmo/EMdata/W002/S2-W002_Sec100_Montage');
secB = initialize_section('/data/home/talmo/EMdata/W002/S2-W002_Sec101_Montage');

% Load images
tic;
tileA = imread(secA.tiles(1).path);
tileB = imread(secB.tiles(1).path);
fprintf('Loaded images in %.2fs.', toc)

%% Resize
tic;
tileA_small = imresize(tileA, 0.25);
tileB_small = imresize(tileB, 0.25);
fprintf('Resized images in %.2fs.', toc)

%% Find features
tic;
[ptsA, descA] = find_features(tileA, 'surf');
[ptsB, descB] = find_features(tileB, 'surf');
fprintf('Found %d and %d features in full images in %.2fs', size(ptsA, 1), size(ptsB, 1), toc)

tic;
[ptsA_small, descA_small] = find_features(tileA_small, 'surf');
[ptsB_small, descB_small] = find_features(tileB_small, 'surf');
fprintf('Found %d and %d features in small images in %.2fs', size(ptsA_small, 1), size(ptsB_small, 1), toc)

%% Match features
tic;
matches = match_features(ptsA, descA, ptsB, descB);
fprintf('Found %d matches in full images in %.2fs', size(matches, 1), toc)
tic;
matches_small = match_features(ptsA_small, descA_small, ptsB_small, descB_small);
fprintf('Found %d matches in small images in %.2fs', size(matches_small, 1), toc)

%% Plot matches
plot_matches(ptsA_small(matches_small(:, 1)), ptsB_small(matches_small(:, 2)));
plot_matches(ptsA_small(matches_small(:, 1)), ptsB_small(matches_small(:, 2)));