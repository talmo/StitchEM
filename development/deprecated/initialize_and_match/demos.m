%% Show registration vs grid initialization
sec_num = 1;
visualization_scale = 0.075;

% Initialize section (load images)
sec = sec_struct(sec_num);

% Get alignments
grid_aligned = estimate_tile_grid_alignments();
registration_aligned = rough_align_tiles(sec);

% Merge and display
figure, imshow_section(sec.num, grid_aligned, 'tile_imgs', sec.img.tiles, 'method', 'max', 'scale', visualization_scale);
figure, imshow_section(sec.num, registration_aligned, 'tile_imgs', sec.img.tiles, 'method', 'max', 'scale', visualization_scale);

%% Feature detection
sec_num = 1;
visualization_scale = 0.1;

% Initialize section (load images)
sec = sec_struct(sec_num);
grid_align = estimate_tile_grid_alignments();

% Detect features
sec.features = detect_section_features(sec.img.tiles, grid_align, 'section_num', sec.num);

% Show features in the section
figure, imshow_section(sec.num, grid_align, 'tile_imgs', sec.img.tiles, 'method', 'max', 'scale', visualization_scale);

% Plot features
hold on; plot_features(sec.features, visualization_scale); hold off

