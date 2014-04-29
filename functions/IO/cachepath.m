function cur_path = cachepath(path)
%CACHEPATH Gets or sets the cache path.

persistent cache_path;

if nargin > 0
    if exist(path, 'dir')
        cache_path = path;
    else
        error('Specified wafer path does not exist.')
    end
end

if isempty(cache_path)
    cache_path = GetFullPath(fullfile(mfilename('fullpath'), '../../../cache'));
end
if ~exist(cache_path, 'dir')
    error('Current cache path does not exist. Call this function with the path to the cache as the parameter to set it.\nCurrent path: %s', cache_path)
end

cur_path = cache_path;
end

