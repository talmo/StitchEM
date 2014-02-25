% Deletes the data folder below and all subfiles/folders.
% Careful with this one!

cache_path = '/data/home/talmo/EMdata/W002/StitchData';

response = input('Are you sure you want to delete entire the cache? ([Y]es/[N]o)\n', 's');
if strcmpi(response(1), 'y')
    if isdir(cache_path)
        rmdir(cache_path, 's');
        fprintf('%s deleted.\n', cache_path)
    else
        fprintf('%s does not exist.\n', cache_path)
    end
end
clear response cache_path
