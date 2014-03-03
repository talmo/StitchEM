function section_path = get_section_path(sec_num)
%GET_SECTION_PATH Returns the path to a section.

% Paths
data_path = '/data/home/talmo/EMdata/W002';
section_foldername_pattern = 'S2-W002_Sec%d_Montage';

% Find path to section
section_path = fullfile(data_path, sprintf(section_foldername_pattern, sec_num));


end

