function section_path = get_section_path(sec_num, wafer_path)
%GET_SECTION_PATH Returns the path to a section.
% Usage:
%   section_path = get_section_path(sec_num)
%   section_path = get_section_path(sec_num, wafer_path)

if nargin < 2
    wafer_path = waferpath;
end

info = get_path_info(wafer_path);

if info.exists && strcmp(info.type, 'wafer')
    idx = find(info.sec_nums == sec_num, 1);
    if ~isempty(idx)
        section_path = fullfile(info.path, info.section_folders{idx});
    else
        error('Could not find path to section %d.', sec_num)
    end
else
    error('Path to wafer does not exist or contain sections.\nPath: %s', wafer_path)
end
end

