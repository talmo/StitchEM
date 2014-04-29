% Checks for bad initialization, feature detection or matching of a stack.

%% Load stack and matches
load('sec1-149_matches.mat') % doesn't have features or images

%% Stack info
% Section numbers
sec_nums = unique([unique(matchesA.section); unique(matchesB.section)]);
num_secs = length(sec_nums);

% Tiles in each section
sec_tiles = arrayfun(@(s) unique([unique(matchesA.tile(matchesA.section == s)); unique(matchesB.tile(matchesB.section == s))]), sec_nums, 'UniformOutput', false);

%% Find missing XY matches
tic;
tiles_missing_xy = arrayfun(@(s) find(~arrayfun(@(t) any((matchesA.tile == t | matchesB.tile == t) & (matchesA.section == sec_nums(s) & matchesB.section == sec_nums(s))), sec_tiles{s})), 1:num_secs, 'UniformOutput', false);
toc % Elapsed time is 44.918443 seconds.

% Find sections with tiles missing XY matches
secs_missing_xy = sec_nums(find(~cellfun('isempty', tiles_missing_xy)));
fprintf('Sections that failed XY matching: %s\n', strtrim(strjoin(cellstr(num2str(secs_missing_xy))', ', ')))

%% Render rough aligned sections with missing XY matches
render_scale = 0.015;
rough_secs = cell(size(secs_missing_xy));
for i = 1:length(secs_missing_xy)
    rough_secs{i} = render_section(secs{secs_missing_xy(i)}, 'render_scale', render_scale);
end

% Display them for inspection
grid_size = [4 4];
figure, hold on
for i = 1:prod(grid_size):length(rough_secs)
    clf
    for j = 0:prod(grid_size) - 1
        subplot(grid_size(1), grid_size(2), j + 1)
        if i + j <= length(rough_secs)
            subimage(rough_secs{i + j})
            title(sprintf('Section %d', secs_missing_xy(i + j)))
        end
    end
    disp('Press any key to continue.'), pause
end
hold off

%% Try to fix bad grid rough alignment
s = 4;

% Load section with bad grid alignment
sec = load_sec(secs_missing_xy(s), 'load_tiles', true);

% Find and plot matches with bad grid alignment
match_section_features(sec, 'verbosity', 1, 'show_matches', true);

% Clear grid aligned transforms
[sec.rough_tforms{sec.grid_aligned}] = deal({});

% Recalculate grid aligned transforms
sec.rough_tforms = estimate_tile_grid_alignments(sec.rough_tforms);

% Re-detect features with new overlap regions
sec = detect_section_features(sec);

% Find and plot matches with fixed grid alignment
match_section_features(sec, 'verbosity', 1, 'show_matches', true);

%% Find sections that failed overview registration
failed_overview_secs = find(cellfun(@(sec) ~isempty(sec) && all(all(sec.overview_tform.T == eye(3))) && sec.num ~= 1, secs));
fprintf('Sections that failed overview registration: %s\n', vec2str(failed_overview_secs))

%% Try to register overviews
s = 4; % 2:6

% Load sections
sec = load_sec(failed_overview_secs(s), 'load_overview', true);
last_sec = load_sec(sec_nums(find(sec_nums == failed_overview_secs(s), 1) - 1), 'load_overview', true);

% Register overviews
register_overviews(sec, last_sec, 'show_registration', true, 'verbosity', 2);

% Inspect them visually
imshowpair(sec.img.overview, last_sec.img.overview, 'montage')

%% Inspect suspicious sections based on features
% Check:
% - failed_feature_detection (cell)
% - failed_overview_registration (cell)
% - num_grid_aligned (m x 1 vector)
% - num_features_xy
% - num_features_z

% List sections by order of # of tiles grid_aligned
[num_grid_aligned_sorted, num_grid_aligned_sorted_idx] = sort(num_grid_aligned, 'descend');
top_grid_aligned_idx = num_grid_aligned_sorted ~= 0;
disp('Sections with grid aligned tiles:')
disp(num2str([num_grid_aligned_sorted_idx(top_grid_aligned_idx),  num_grid_aligned_sorted(top_grid_aligned_idx)], '%d: %d\n'))


%% Inspect suspicious sections based on matches
% Failed XY matching (entire section)
fprintf('Sections that failed XY matching: %s\n', vec2str(failed_xy_matching))

% Failed XY tile matching
disp('Failed seams (XY):')
secs_with_failed_tile_pairs = find(~cellfun('isempty', failed_tile_pairs));
for i = 1:length(secs_with_failed_tile_pairs)
    s = secs_with_failed_tile_pairs(i);
    failed_pairs = cellfun(@(v) vec2str(v, '->'), failed_tile_pairs{s}, 'UniformOutput', false);
    fprintf(' - Sec%d: %s\n', s, strjoin(failed_pairs, ', '))
end

% Sort by number of XY matches
k = 20; % bottom k
[num_xy_matches_sorted, num_xy_matches_sorted_idx] = sort(num_xy_matches, 'ascend');
disp('Sections sorted by # of XY matches:')
disp(num2str([num_xy_matches_sorted_idx(1:k),  num_xy_matches_sorted(1:k)], '%d: %d\n'))


% Failed Z matching
fprintf('Sections that failed Z matching: %s\n', strjoin(cellfun(@(v) vec2str(v, '->'), failed_section_pairs, 'UniformOutput', false), ', '))

% Sort by number of Z matches
k = 20; % bottom k
[num_z_matches_sorted, num_z_matches_sorted_idx] = sort(num_z_matches, 'ascend');
disp('Sections sorted by # of Z matches:')
disp(num2str([num_z_matches_sorted_idx(1:k),  num_z_matches_sorted(1:k)], '%d: %d\n'))

%% Visualize matches
i = 89; j = i-1;

% XY matches:
figure, imshow_section(load_sec(i));
plot_section_matches(matchesA, matchesB, i);
plot_seams(secs{i}.rough_tforms, 0.025)

% Z matches:
%figure, imshow_section_matches(matchesA, matchesB, i, j);

%% Show a pair of sections with the Z matches
i = 51; j = i-1;

figure, imshow_section_pair(i, j);
plot_section_matches(matchesA, matchesB, i, j);

%% Features
% Run through the cached features gathering info:
%
% [X] List sections that failed to register overview: failed_overview_registration
% [X] List sections that failed feature detection: failed_feature_detection
% [X] List sections by order of # of tiles grid aligned: num_grid_aligned
% [X] List sections by number of XY features: num_features_xy
% [X] List sections by number of Z features: num_features_z

% Sections with grid aligned tiles
%grid_aligned = find(cellfun(@(s) ~isempty(s) && ~isempty(s.grid_aligned), secs));

%% Matches
% Run through matches gathering info:
%
% [X] List sections that failed XY matching: failed_xy_matching
% [X] List sections by # XY matches: num_xy_matches
% [ ] List sections/tiles by average XY match displacement
%
% [X] List section pairs that failed Z matching: failed_section_pairs
% [X] List section pairs by # Z matches: num_z_matches
% [ ] List sections/tiles by average Z match displacement
