function tile_img = imshow_tile(section_num, tile_num, suppress_display)
%IMSHOW_TILE Shows the specified section -> tile.

if nargin < 3
    suppress_display = false;
end

data_path = '/data/home/talmo/EMdata/W002';
section_path = fullfile(data_path, sprintf('S2-W002_Sec%d_Montage', section_num));
tile_image_paths = find_tile_images(section_path, true);

tile_img = imread(tile_image_paths{tile_num});

if ~suppress_display
    imshow(tile_img)
end
end

