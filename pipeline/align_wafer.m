%% Configuration
% Wafer and sections
%waferpath('/mnt/data0/ashwin/07122012/S2-W003')
waferpath('/data/home/talmo/EMdata/S2-W003')
info = get_path_info(waferpath);
wafer = info.wafer;
sec_nums = info.sec_nums;
%sec_nums = 1:30;

% Load default parameters
default_params

%% Custom per-section parameters
% Note: The index of params corresponds to the actual section number.
% 
% Example:
%   => Change the NNR MaxRatio of section 38:
%   params(38).z.NNR.MaxRatio = 0.8;
%
%   => Set the max match error for sections 10 to 15 to 2000:
%   params(10).z.max_match_error = 2000; % change section 10's parameters
%   [params(11:15).z] = deal(params(10).z); % copy it to sections 11-15
%       Or:
%   for s=10:15; params(s).z.max_match_error = 2000; end

% S2-W002:
% params(2).z = manual_matching;
% params(14).z = rel_to_2previous;
% params(17).z = manual_matching;
% params(18).z = manual_matching;
% params(20).z = manual_matching;
% params(71).z = manual_matching;
% params(72).z = rel_to_2previous;
% params(87).z = low_res;
% params(88).z = manual_matching;
% params(89).z = rel_to_2previous;
% params(134).z = large_trans;
% params(135).z = large_trans;
% params(136).z = large_trans;

% S2-W003:
% Section 72 is rotated by quite a bit, but 73 goes back to normal
params(72).z = large_trans;
params(73).z = rel_to_2previous;
params(140).z = ignore_z_error;
params(141).z = rel_to_2previous;

%% Run alignment
align_stack_xy
align_stack_z