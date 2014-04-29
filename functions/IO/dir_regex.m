function matches = dir_regex(path, expression, folders_only)
%DIR_REGEX Returns contents in a the path matching a regular expression.

if nargin < 3
    folders_only = false;
end

path_contents = dir(path);
if folders_only
    path_contents = {path_contents([path_contents.isdir]).name}';
else
    path_contents = {path_contents.name}';
end

matches = path_contents(~areempty(regexp(path_contents, expression)));

if length(matches) == 1
    matches = matches{1};
end

end

