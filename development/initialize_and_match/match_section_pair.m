% Defaults for testing
fixed_sec_num = 1;
moving_sec_num = 2;
visualization_scale = 0.075;

%% Initialize sections and load images
disp('==== Loading sections and images.')
secA = sec_struct(fixed_sec_num);
secB = sec_struct(moving_sec_num);

%% Register montage overviews
disp('==== Registering section overview images.')
secA.overview_tform = affine2d();
try
    secB.overview_tform = register_overviews(secA.img.overview, secA.overview_tform, secB.img.overview);
catch err
    fprintf('Registration might have failed: %s\nDisplaying the merge.\n', err.message)
    secB.overview_tform = register_overviews(secA.img.overview, secA.overview_tform, secB.img.overview, 'show_registration', true);
end

%% Do a rough alignment on the tiles using the registered overviews
disp('==== Estimating rough tile alignments.')
secA.rough_alignments = rough_align_tiles(secA);
secB.rough_alignments = rough_align_tiles(secB);

%% Visualize rough alignments
disp('==== Merging the rough tile alignments.')
[secA_rough, secA_rough_R] = imshow_section(fixed_sec_num, secA.rough_alignments, 'tile_imgs', secA.img.tiles, 'method', 'max', 'scale', visualization_scale, 'suppress_display', true);
[secB_rough, secB_rough_R] = imshow_section(moving_sec_num, secB.rough_alignments, 'tile_imgs', secB.img.tiles, 'method', 'max', 'scale', visualization_scale, 'suppress_display', true);
[rough_registration, rough_registration_R] = imfuse(secA_rough, secA_rough_R, secB_rough, secB_rough_R);
%figure, imshow(rough_registration)
%title('Rough section registration')
%integer_axes(1/visualization_scale)

%% Detect features at full resolution
disp('==== Detecting finer features at high resolution.')
secA.features = detect_section_features(secA.img.tiles, secA.rough_alignments, 'section_num', secA.num);
secB.features = detect_section_features(secB.img.tiles, secB.rough_alignments, 'section_num', secB.num);

%% Match features across the two sections
disp('==== Match finer features across sections.')
[matchesA, matchesB, regions, region_data] = match_feature_sets(secA.features, secB.features, ...
    'show_region_stats', false, 'verbosity', 0);

%% Visualize matches
% Show the merged rough aligned tiles
figure, imshow(rough_registration, rough_registration_R), hold on

% Show the matches
plot_matches(matchesA.global_points, matchesB.global_points, visualization_scale)

% Adjust the figure
title(sprintf('Matches between sections %d and %d (n = %d)', secA.num, secB.num, size(matchesA, 1)))
integer_axes(1/visualization_scale)
hold off