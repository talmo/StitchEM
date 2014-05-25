function created_path = create_folder(folder_path)
%CREATE_FOLDER Creates a new folder without overwriting a non-empty existing one.
% Usage:
%   created_path = create_folder(folder_path)
%
% See also: get_new_path

% Get absolute path to the folder
base_path = GetFullPath(folder_path);

% Add number to name if needed
folder_num = 1;
created_path = base_path;
while exist(created_path, 'dir') && ~isempty(ls(created_path))
    folder_num = folder_num + 1;
    created_path = [base_path '(' num2str(folder_num) ')'];
end

% Create folder
if ~exist(created_path, 'dir')
    mkdir(created_path);
end
end

