function overview_img = imload_overview(sec_num, scale, wafer_path)
%IMLOAD_OVERVIEW Loads the overview image for a given section.

if nargin < 2
    scale = 1.0;
end
if nargin < 3
    wafer_path = waferpath;
end
overview_img = imread(get_overview_path(sec_num, wafer_path));

if scale ~= 1.0
    overview_img = imresize(overview_img, scale);
end

end
