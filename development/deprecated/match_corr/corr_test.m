%% Load sections
% Parameters
cache_path = './sec_cache'; % Load features from here
sec_num = 101;

sec = load_sec(sec_num, 'cache_path', cache_path);
last_sec = load_sec(sec_num - 1, 'cache_path', cache_path);

%% Match
% Find matches
[z_matchesA, z_matchesB] = match_section_pair(sec, last_sec, 'show_matches', true);

%% Get matches from tile 1 only
tile1_idx = z_matchesA.tile == 1 | z_matchesB.tile == 1;
tile1_matchesA = z_matchesA(tile1_idx, :);
tile1_matchesB = z_matchesB(tile1_idx, :);

%% Visualize tile pair
display_scale = 0.1;

% Load images
tile1_A = imload_tile(sec.num, 1);
tile1_B = imload_tile(last_sec.num, 1);

% Display
imshow_tile_pair(tile1_A, tile1_B, ...
    sec.rough_tforms{1}, last_sec.rough_tforms{1}, ...
    'blending_method', 'falsecolor', 'display_scale', display_scale)
plot_matches(tile1_matchesA, tile1_matchesB, display_scale)

%% Statistics
tile1_dists = calculate_match_distances(tile1_matchesA, tile1_matchesB);
figure, hist(tile1_dists, 20), title(sprintf('n = %d', length(tile1_dists)))
figure, probplot('normal', tile1_dists) % good for seeing the dispersion

%% Refine using cpcorr
local_ptsA = sec.rough_tforms{1}.transformPointsInverse(tile1_matchesA.global_points);
local_ptsB = last_sec.rough_tforms{1}.transformPointsInverse(tile1_matchesB.global_points);

moving = tile1_A;
fixed = tile1_B;

movingPoints = local_ptsA;
fixedPoints = local_ptsB;

movingPointsAdjusted = cpcorr(movingPoints, fixedPoints, moving, fixed);

tile1_matchesA_cpcorr = sec.rough_tforms{1}.transformPointsForward(movingPointsAdjusted);
tile1_matchesB_cpcorr = tile1_matchesB;

% Statistics
tile1_dists_cpcorr = calculate_match_distances(tile1_matchesA_cpcorr, tile1_matchesB_cpcorr);
figure, hist(tile1_dists_cpcorr, 20), title(sprintf('n = %d', length(tile1_dists_cpcorr)))
figure, probplot('normal', tile1_dists_cpcorr) % good for seeing the dispersion

%% Refine using normxcorr2?

