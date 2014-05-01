function info = get_path_info(path)
%GET_PATH_INFO Returns info on the tile or section based on the path.

% Defaults
info.sec_num = 0;
info.tile_num = 0;
info.row = 0;
info.col = 0;
info.is_section_folder = 0;
info.is_tile = 0;

% Split the path
[section_path, filename, ext] = fileparts(path);

switch ext
    case ''
        % Analyze section path
        section_path_pattern = '.*_Sec(?<sec>[0-9]*)_Montage';
        section_path_tokens = regexp(filename, section_path_pattern, 'names');
        info.sec_num = str2double(section_path_tokens.sec);
        info.is_section_folder = 1;
        
    case '.tif'
        % Analyze tile filename
        tile_filename_pattern = 'Tile_r(?<row>[0-9]*)-c(?<col>[0-9]*)_.*_sec(?<sec>[0-9]*).tif';
        filename_tokens = regexp([filename ext], tile_filename_pattern, 'names');

        % Collect info
        info.row = str2double(filename_tokens.row);
        info.col = str2double(filename_tokens.col);
        info.sec_num = str2double(filename_tokens.sec);
        info.tile_num = (info.row - 1) * 4 + info.col;
        info.is_tile = 1;
        
    otherwise
        error('Not a valid path or filename for a section folder or a tile image.')
end

end

