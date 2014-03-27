function overview_img = imload_overview(sec_num)
%IMLOAD_MOTAGE Loads the overview image for a given section.

section_path = get_section_path(sec_num);
overview_path = fullfile(section_path, sprintf('MontageOverviewImage_S2-W002_sec%d.tif', sec_num));

overview_img = imread(overview_path);

end
