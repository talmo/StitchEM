% Prepares the environment so you can use StitchEM correctly.

%% Paths
script_path = pwd;

% Check if we have our critical folders
if ~isdir('functions')
    response = input(['It appears this script is missing some essential folders.\n' ...
        'This may be because the program was downloaded incorrectly.\n\n' ...
        'The necessary scripts may not be in the path, do you want to continue anyway? ([Y]es/[N]o)\n'], 's');
    if ~strcmpi(response(1), 'y')
        fprintf('Stopping initialization. Try re-downloading StitchEM.\n')
        return
    end
    clear response
end

%% Add paths
% Add all the functions and classes for StitchEM to the path so they are
% callable from anywhere
addpath(genpath(fullfile(script_path, 'classes')));
addpath(genpath(fullfile(script_path, 'functions')));
addpath(genpath(fullfile(script_path, 'development', 'utils')));
addpath(genpath(fullfile(script_path, 'development', 'xyz_align')));
clear script_path