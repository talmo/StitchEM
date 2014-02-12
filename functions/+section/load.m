function section = load(path)
%LOAD Loads a section structure from cached metadata.
% Path can be the path to any of:
% - The direct path to the stitch_metadata.mat file for the section
% - The folder containing the stitch data files for the section
% - The folder containing the raw images
% The last option assumes that the data folder is in '../StitchData'.

% Initialize final path
metadata_path = '';

% This is the direct path to the section metadata
if strfind(path, 'metadata.mat')
    metadata_path = path;

% Figure out if this is the path to the raw image folder or the data folder
else
    % Check if folder exists
    if ~exist(path, 'dir')
        error('The section folder at the specified path does not exist.')
    end
    
    % Check if metadata file exists
    if exist(fullfile(path, 'metadata.mat'), 'file')
        % This is the data folder
        metadata_path = fullfile(path, 'metadata.mat');
        
    else
        % This is the raw image folder
        [parent_path, sec_folder] = fileparts(path);
        metadata_path = fullfile(parent_path, 'StitchData', sec_folder, 'metadata.mat');
    end
end

% Check if the detected path exists
if ~exist(metadata_path, 'file')
    error(['The metadata file for this section does not exist\n.' ...
        '\tPath: %s\n' ...
        'This section may not have been initialized. Run section.initialize() with the path to the raw images folder.'], metadata_path)
end

% Load the section metadata file
cache = load(metadata_path);
section = cache.section;

end

