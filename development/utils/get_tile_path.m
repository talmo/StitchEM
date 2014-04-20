function tile_path = get_tile_path(sec_num, tile_num, wafer_path)
%GET_TILE_PATH Returns the path to a tile.

if nargin < 3
    wafer_path = '/data/home/talmo/EMdata/W002';
end

% Find all tile paths
tile_image_paths = find_tile_images(get_section_path(sec_num, wafer_path), true);

% Return single tile path
tile_path = tile_image_paths{tile_num};

end

