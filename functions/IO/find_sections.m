function section_folders = find_sections(return_full_paths, wafer_path)
%FIND_SECTIONS Scans a directory for section folders.

if nargin < 1
    return_full_paths = false;
end
if nargin < 2
    wafer_path = waferpath;
end

info = get_path_info(wafer_path);

if strcmp(info.type, 'wafer') && info.exists
    section_folders = info.section_folders;
    if return_full_paths
        % Append path
        section_folders = strcat(repmat(info.path, size(info.section_folders)), info.section_folders);
    end
else
    error('Could not find section folders in specified path.\nPath: %s', wafer_path)
end
end

