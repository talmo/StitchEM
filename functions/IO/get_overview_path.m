function overview_path = get_overview_path(sec, wafer_path)
%GET_OVERVIEW_PATH Returns the path to a section.
% Usage:
%   overview_path = get_overview_path(sec_struct)
%   overview_path = get_overview_path(sec_num)
%   overview_path = get_overview_path(sec_num, wafer_path)

if isstruct(sec) && isfield(sec, 'overview') && isfield(sec.overview, 'path')
    overview_path = sec.overview.path;
elseif isstruct(sec) && isfield(sec, 'path')
    sec_path = sec.path;
    info = get_path_info(sec_path);
    overview_path = fullfile(info.path, info.overview);
else
    if nargin < 2; wafer_path = waferpath; end
    sec_path = get_section_path(sec, wafer_path);
    info = get_path_info(sec_path);
    overview_path = fullfile(info.path, info.overview);
end

if isempty(overview_path)
    error('Could not find overview image in section folder.\nPath: %s', sec_path);
end

end

