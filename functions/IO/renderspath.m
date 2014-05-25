function current_path = renderspath(new_path)
%RENDERSPATH Gets or sets the renders path. Creates the folder if it doesn't exist.
% Usage:
%   current_path = renderspath
%   renderspath(new_path)

global ProgramPaths;

% Update
if nargin > 0
    ProgramPaths.renders = GetFullPath(new_path);
    disp('Set render path.')
end

% Defaults
if isempty(ProgramPaths) || ~isfield(ProgramPaths, 'base')
    ProgramPaths.base = GetFullPath(fullfile(mfilename('fullpath'), '../../..'));
end
if ~isfield(ProgramPaths, 'renders')
    ProgramPaths.renders = fullfile(ProgramPaths.base, 'renders');
    disp('Render path not set, using default.')
end

% Create if doesn't exist
if ~exist(ProgramPaths.renders, 'dir')
    mkdir(ProgramPaths.renders);
end

% Return current
current_path = ProgramPaths.renders;
end

