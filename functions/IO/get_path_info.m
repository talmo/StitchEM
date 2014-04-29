function info = get_path_info(path)
%GET_PATH_INFO Returns info on the tile or section based on the path.

%% Regular expressions for naming patterns
% Change these if using a different naming convention
section_pattern = '(?<wafer>S\d+-W\d+)_Sec(?<sec>\d+)_Montage$';
tile_pattern = 'Tile_r(?<row>\d+)-c(?<col>\d+)_(?<wafer>S\d+-W\d+)_sec(?<sec>\d+).*[.]tif$';
overview_pattern = 'MontageOverviewImage_(?<wafer>S\d+-W\d+)_sec(?<sec>\d+).tif$';

%% Parse the path
info.path = path;
info.exists = logical(exist(path));
info.type = '';

% Test path against patterns
sec_matches = regexp(path, section_pattern, 'names');
tile_matches = regexp(path, tile_pattern, 'names');
overview_matches = regexp(path, overview_pattern, 'names');

if ~isempty(tile_matches)
    info.type = 'tile';
    info.wafer = tile_matches.wafer;
    info.section = str2double(tile_matches.sec);
    info.row = str2double(tile_matches.row);
    info.col = str2double(tile_matches.col);
    [info.sec_path, filename, ext] = fileparts(path);
    info.wafer_path = fileparts(info.sec_path);
    info.filename = [filename ext];
    if info.exists
        info.sec_tiles = length(dir_regex(info.sec_path, tile_pattern));
        info.index = find(ismember(dir_regex(info.sec_path, tile_pattern), info.filename));
    end
    
elseif ~isempty(overview_matches)
    info.type = 'overview';
    info.wafer = overview_matches.wafer;
    info.section = str2double(overview_matches.sec);
    [info.sec_path, filename, ext] = fileparts(path);
    info.wafer_path = fileparts(info.sec_path);
    info.filename = [filename ext];
    
elseif ~isempty(sec_matches)
    info.type = 'section';
    info.wafer = sec_matches.wafer;
    info.section = str2double(sec_matches.sec);
    if info.exists
        info.tiles = dir_regex(path, tile_pattern);
        info.num_tiles = length(info.tiles);
        info.overview = dir_regex(path, overview_pattern);
    end
elseif info.exists
    % This is a wafer folder if it contains section folders
    path_secs = dir_regex(path, section_pattern);
    
    if ~isempty(path_secs)
        info.type = 'wafer';
        [~, info.wafer] = fileparts(path);
        info.num_secs = length(path_secs);
        sec_names = regexp(path_secs, section_pattern, 'names');
        [info.sec_nums, idx] = sort(cellfun(@(s) str2double(s.sec), sec_names));
        info.section_folders = path_secs(idx);
        info.missing_secs = find(~ismember(min(info.sec_nums):max(info.sec_nums), info.sec_nums)');
    end
end

if isempty(info.type)
    warning('Specified path is not a wafer, section or tile folder.')
end
end

