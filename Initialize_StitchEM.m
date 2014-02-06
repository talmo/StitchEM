% Prepares the environment so you can use StitchEM correctly.

%% Paths
script_path = pwd;

% Check if we have our critical folders
if ~isdir('+pipeline') || ~isdir('functions')
    response = input(['It appears this script is missing some essential folders.\n' ...
        'This may be because the program was downloaded incorrectly.\n\n' ...
        'The necessary scripts may not be in the path, do you want to continue anyway? ([Y]es/[N]o)\n'], 's');
    if ~strcmpi(response(1), 'y')
        fprintf('Stopping initialization. Try re-downloading StitchEM.\n')
        return
    end
    clear response
end

% Add all the functions and scripts for StitchEM to the path so they are
% callable from anywhere.
addpath(genpath(pwd));

%% Packages
% Import utility functions so we don't need to qualify function calls
import utilities.*
