function tile_paths = get_tile_paths(sec, wafer_path)
%GET_TILE_PATHS Returns the paths to the tiles in the section.
% Usage:
%   tile_paths = get_tile_paths(sec_struct)
%   tile_paths = get_tile_paths(sec_num)
%   tile_paths = get_tile_paths(sec_num, wafer_path)

if isstruct(sec) && isfield(sec, 'tile_paths')
    % sec_struct has tile_paths field
    tile_paths = sec.tile_paths;
elseif isstruct(sec) && isfield(sec, 'tile_files') && isfield(sec, 'path')
    % sec_struct has tile_files field (legacy)
    tile_paths = fullfile(sec.path, sec.tile_files);
elseif isstruct(sec) && isfield(sec, 'path')
    % sec_struct has path field
    info = get_path_info(sec.path);
    tile_paths = fullfile(info.path, info.tiles);
else
    % sec_num input
    sec_num = sec;
    if isstruct(sec); sec_num = sec.num; end
    if nargin < 1; wafer_path = waferpath(); end
    
    sec_path = get_section_path(sec_num, wafer_path);
    info = get_path_info(sec_path);
    tile_paths = fullfile(info.path, info.tiles);
end

end

