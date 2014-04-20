function section_path = get_section_path(sec_num, wafer_path)
%GET_SECTION_PATH Returns the path to a section.

if nargin < 2
    wafer_path = '/data/home/talmo/EMdata/W002';
end

section_foldername_pattern = sprintf('*_Sec%d_Montage', sec_num);
path_pattern = fullfile(wafer_path, section_foldername_pattern);

% Find path to section
section_path = dir(path_pattern);

if isempty(section_path)
    error('Could not find path to section: %s', path_pattern)
else
    section_path = fullfile(wafer_path, section_path.name);
end
end

