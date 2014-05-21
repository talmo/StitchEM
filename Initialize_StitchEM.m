% Prepares the MATLAB environment so you can use StitchEM correctly.

%% Configuration Instructions
% To change the patterns used to look for sections/tiles, modify:
%   functions/IO/get_path_info.m

% To change the path to the cache folder, call: waferpath(new_path)

%% Paths
% Add StitchEM functions to MATLAB search path
addpath(genpath(fullfile(pwd, 'functions')));

% Set the current wafer path
%waferpath('/data/home/talmo/EMdata/S2-W003');
waferpath('/data/home/talmo/EMdata/W002');

cd('development/model_fitting');
addpath(pwd);
addpath(fullfile(pwd, 'functions'));
addpath(genpath(fullfile(pwd, 'CPD2')));