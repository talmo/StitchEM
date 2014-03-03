function tile_path = get_tile_path(sec_num, tile_num)
%GET_TILE_PATH Returns the path to a single tile or all tiles in a section.

% Find all tile paths
tile_image_paths = find_tile_images(get_section_path(sec_num), true);

if nargin < 2
    % Return all tile paths
    tile_path = tile_image_paths;
else
    % Return single tile path
    tile_path = tile_image_paths{tile_num};
end

end

