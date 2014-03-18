function sec = sec_struct(sec_num, tile_scale)
% SEC_STRUCT Loads a section and its images based on section number.
% Usage:
%   sec = SEC_STRUCT(sec_num)
%   sec = SEC_STRUCT(sec_num, tile_scale)

if nargin < 2
    tile_scale = 0.25;  % ideally this should be the feature detection scale so we don't have to resize again
end

fprintf('== Loading section %d.\n', sec_num)

% Default values for a section structure
sec.num = sec_num;
sec.num_tiles = 16;
sec.tile_scale = tile_scale;
sec.overview_tform = affine2d();
sec.rough_alignments = cell(sec.num_tiles, 1);
sec.grid_aligned = [];
sec.features = table();
sec.fine_alignments = cell(sec.num_tiles, 1);

% Load montage overview
tic;
sec.img.overview = imshow_montage(sec_num, true);
fprintf('Loaded overview image. [%.2fs]\n', toc)

% Load tile images and resize them
tic
[sec.img.scaled_tiles, sec.img.tiles] = imload_section_tiles(sec.num, tile_scale);
fprintf('Loaded and resized tile images. [%.2fs]\n', toc)
end