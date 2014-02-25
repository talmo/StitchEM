function tile_imgs = find_tile_images(section_path, return_full_paths)
%FIND_TILE_IMAGES Returns a cell array of files matching the tile naming pattern.

% Check if we have the second optional argument
if nargin < 2
    return_full_paths = false;
end

% Check for trailing slash in path
if strcmp(section_path(end), '/') || strcmp(section_path(end), '\')
    section_path = section_path(1:end - 1);
end

% Get files matching pattern
directory_listing = dir([section_path filesep 'Tile_*.tif']);

% Extract folder names from structure into cell array
tile_imgs = {directory_listing.name}';

% Append base path if needed
if return_full_paths
    tile_imgs = cellfun(@(tile_filename) {fullfile(section_path, tile_filename)}, tile_imgs);
end

end

