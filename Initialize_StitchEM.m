% Prepares the MATLAB environment so you can use StitchEM correctly.

%% Configuration Instructions
% To change the patterns used to look for sections/tiles, modify:
%   functions/IO/get_path_info.m

% To change the path to the cache folder, call: waferpath(new_path)

%% Paths
% Add StitchEM files to MATLAB search path
addpath(pwd);
addpath(genpath(fullfile(pwd, 'functions')));
addpath(genpath(fullfile(pwd, 'pipeline')));

% Set paths to data folders
cachepath(fullfile(pwd, 'cache'));
renderspath(fullfile(pwd, 'renders'));

% Set the current wafer path
%waferpath('/data/home/talmo/EMdata/W002');
waferpath('/data/home/talmo/EMdata/S2-W003');

clear ans
%% Development
% cd('development/model_fitting');
% addpath(pwd);
% addpath(fullfile(pwd, 'functions'));
% addpath(genpath(fullfile(pwd, 'CPD2')));