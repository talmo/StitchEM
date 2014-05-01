function tile_paths = get_tile_paths(sec_num, wafer_path)
%GET_TILE_PATH Returns the path to the tiles of a section.

if nargin < 2
    wafer_path = '/data/home/talmo/EMdata/W002';
end

% Find all tile paths
tile_paths = find_tile_images(get_section_path(sec_num, wafer_path), true);

end

