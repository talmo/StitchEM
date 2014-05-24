%% Parameters
% Stack
waferpath('/mnt/data0/ashwin/07122012/S2-W002')
info = get_path_info(waferpath);
sec_nums = info.sec_nums;

% Run parameters
overwrite_secs = false; % errors out if the current section was already aligned
stop_after = 'z'; % 'xy', or 'z'

% Load defaults
default_params

%% Custom parameters
% See default_params for presets
params(2).z = manual_matching;
params(14).z = rel_to_2previous;
params(17).z = manual_matching;
params(18).z = manual_matching;
params(20).z = manual_matching;
params(71).z = manual_matching;
params(72).z = rel_to_2previous;
params(87).z = low_res;
params(88).z = manual_matching;
params(89).z = rel_to_2previous;
params(134).z = large_trans;
params(135).z = large_trans;
params(136).z = large_trans;

%% Run
align_stack_xy
align_stack_z