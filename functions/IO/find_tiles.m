function tile_imgs = find_tiles(section, return_full_paths, wafer_path)
%FIND_TILES Returns the tile images in a section folder.

if nargin < 2
    return_full_paths = false;
end
if nargin < 3
    wafer_path = waferpath;
end

if isnumeric(section)
    section_path = get_section_path(section, wafer_path);
elseif ischar(section)
    section_path = section;
else
    error('Section must specify the number or path to the section.')
end
    


info = get_path_info(section_path);

if strcmp(info.type, 'section') && info.exists
    tile_imgs = info.tiles;
    if return_full_paths
        % Append path
        tile_imgs = strcat(repmat(info.path, size(info.tiles)), repmat(filesep, size(info.tiles)), info.tiles);
    end
else
    error('Could not find tile images in specified path.\nPath: %s', section_path)
end
end

