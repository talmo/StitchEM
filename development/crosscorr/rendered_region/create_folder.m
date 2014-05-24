function created_path = create_folder(folder_path)
%CREATE_FOLDER Creates a new folder without overwriting an existing one.
% Usage:
%   created_path = create_folder(folder_path)

% Get absolute path to the folder
base_path = GetFullPath(folder_path);

% Add number to name if needed
folder_num = 1;
created_path = base_path;
while exist(created_path, 'dir')
    folder_num = folder_num + 1;
    created_path = [base_path ' (' num2str(folder_num) ')'];
end

% Create folder
mkdir(created_path);

end

