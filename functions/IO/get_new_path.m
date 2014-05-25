function new_path = get_new_path(desired_path)
%GET_NEW_PATH Returns a new path based on a desired one to prevent overwriting.
% Usage:
%   new_path = get_new_path(desired_path)
% 
% See also: create_folder

% Break up the absolute path
[pathstr, name, ext] = fileparts(GetFullPath(desired_path));
base_path = fullfile(pathstr, name);

% Iterate until we find a non-existing path with the same base
num = 1;
new_path = [base_path ext];
while exist(new_path)
    new_path = [base_path '(' num2str(num) ')' ext];
end
end

