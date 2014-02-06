function section_folders = find_section_folders(base_path, return_full_paths)
%FIND_SECTION_FOLDERS Scans a directory for section folders.
% (Optional) Set the second argument to true to get a list of full paths
% instead of just the folder names.

% Check if we have the second optional argument
if nargin < 2
    return_full_paths = false;
end

% Check for trailing slash in path
if strcmp(base_path(end), '/') || strcmp(base_path(end), '\')
    base_path = base_path(1:end - 1);
end

% Find folders matching pattern for section folder naming
directory_listing = dir([base_path filesep '*Sec*_*']);

% Extract folder names from structure into cell array
section_folders = {directory_listing([directory_listing.isdir]).name}';

% Append base path if needed
if return_full_paths
    section_folders = cellfun(@(folder_name) {fullfile(base_path, folder_name)}, section_folders);
end

end

