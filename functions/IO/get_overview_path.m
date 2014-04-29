function overview_path = get_overview_path(sec_num, wafer_path)
%GET_OVERVIEW_PATH Returns the path to a section.

if nargin < 2
    wafer_path = waferpath;
end
sec_path = get_section_path(sec_num, wafer_path);
info = get_path_info(sec_path);

if isempty(info.overview)
    error('Could not find overview image in section folder.\nPath: %s', sec_path);
end

overview_path = fullfile(info.path, info.overview);
end

