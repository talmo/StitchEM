function sec = sec_struct(sec_num)
fprintf('== Loading section %d.\n', sec_num)

% Default values for a section structure
sec.num = sec_num;
sec.num_tiles = 16;
sec.overview_tform = affine2d();
sec.rough_alignments = cell(sec.num_tiles, 1);
sec.features = table();

% Load montage overview
tic;
sec.img.overview = imshow_montage(sec_num, true);
fprintf('Loaded overview image. [%.2fs]\n', toc)

% Load tile images
tic
tiles = cell(sec.num_tiles, 1);
parfor tile_num = 1:sec.num_tiles
    tiles{tile_num} = imload_tile(sec_num, tile_num);
end
sec.img.tiles = tiles;
fprintf('Loaded tile images. [%.2fs]\n', toc)
end