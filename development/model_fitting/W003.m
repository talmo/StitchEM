%% Parameters
% Stack
waferpath('/mnt/data0/ashwin/07122012/S2-W003')
info = get_path_info(waferpath);
sec_nums = info.sec_nums;

% Run parameters
overwrite_secs = false; % errors out if the current section was already aligned
stop_after = 'z'; % 'xy', or 'z'

% Load defaults
default_params

%% Custom parameters
% See default_params for presets
params(72).z = ignore_z_error;
params(73).z = ignore_z_error;

%% Run
align_stack_xy
align_stack_z