function overview_img = imload_overview(sec_num, wafer_path)
%IMLOAD_MOTAGE Loads the overview image for a given section.

if nargin < 2
    wafer_path = '/data/home/talmo/EMdata/W002';
end

section_path = get_section_path(sec_num, wafer_path);
path_pattern = fullfile(section_path, 'MontageOverviewImage_*.tif');

overview_path = dir(path_pattern);

if isempty(overview_path)
    error('Could not find section overview: %s', overview_path)
else
    overview_path = overview_path.name;
    overview_path = fullfile(section_path, overview_path);
end

overview_img = imread(overview_path);

end
