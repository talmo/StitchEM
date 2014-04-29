% Prepares the MATLAB environment so you can use StitchEM correctly.

%% Paths
% Add StitchEM functions to MATLAB search path
addpath(genpath(fullfile(pwd, 'functions')));

% Set the current wafer path
waferpath('/data/home/talmo/EMdata/W002');

% To change the patterns used to look for sections/tiles, modify:
%   functions/IO/get_path_info.m

% To change the path to the cache folder, call: waferpath(new_path)