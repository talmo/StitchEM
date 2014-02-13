function stack = load(path)
%LOAD Loads a saved stack metadata from cache.

% Check if the path exists
if ~exist(path, 'file') && ~exist(path, 'dir')
    error('The path specified does not exist.')
end

% Path is to the actual metadata file
if ~isempty(strfind(path, 'stack_data.mat')) && exist(path, 'file')
    metadata_path = path;

% Path is to the StitchData folder
elseif exist(fullfile(path, 'stack_data.mat'), 'file')
    metadata_path = fullfile(path, 'stack_data.mat');

% Path is to the wafer folder
elseif exist(fullfile(path, 'StitchData', 'stack_data.mat'), 'file')
    metadata_path = fullfile(path, 'StitchData', 'stack_data.mat');

% Path is a folder but it doesn't contain the cached metadata file
else
    error(['The cached stack data file could not be found in the path.\n' ...
        '\tPath: %s\n' ...
        'Make sure stack_data.mat is in the path or use stack.initialize() to generate a new stack data file.'], path)
end

% Load the cached file
cache = load(metadata_path, 'stack');
stack = cache.stack;

fprintf('Loaded stack metadata for wafer %s (saved on %s).\n', stack.wafer, stack.time_stamp)

end

