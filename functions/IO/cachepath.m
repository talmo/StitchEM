function current_path = cachepath(new_path)
%CACHEPATH Gets or sets the cache path. Creates the folder if it doesn't exist.
% Usage:
%   current_path = cachepath
%   cachepath(new_path)

global ProgramPaths;

% Update
if nargin > 0
    ProgramPaths.cache = GetFullPath(new_path);
    disp('Set cache path.')
end

% Defaults
if isempty(ProgramPaths) || ~isfield(ProgramPaths, 'base')
    ProgramPaths.base = GetFullPath(fullfile(mfilename('fullpath'), '../../..'));
end
if ~isfield(ProgramPaths, 'cache')
    ProgramPaths.cache = fullfile(ProgramPaths.base, 'cache');
    disp('Cache path not set, using default.')
end

% Create if doesn't exist
if ~exist(ProgramPaths.cache, 'dir')
    mkdir(ProgramPaths.cache);
end

% Return current
current_path = ProgramPaths.cache;
end

