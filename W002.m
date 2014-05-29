%% Configuration
% Wafer and sections
%waferpath('/mnt/data0/ashwin/07122012/S2-W002')
waferpath('/data/home/talmo/EMdata/W002')
info = get_path_info(waferpath);
wafer = info.wafer;
sec_nums = info.sec_nums;

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
% XY
params(1).xy.matching.filter_method = 'gmm';
params(1).xy.matching.filter_fallback = 'geomedian';

% Z
params(2).z = z_presets.manual_matching;
params(14).z = z_presets.rel_to_2previous;
params(17).z = z_presets.manual_matching;
params(18).z = z_presets.manual_matching;
params(20).z = z_presets.manual_matching;
params(71).z = z_presets.manual_matching;
params(72).z = z_presets.rel_to_2previous;
params(87).z = z_presets.low_res;
params(88).z = z_presets.manual_matching;
params(89).z = z_presets.rel_to_2previous;
params(134).z = z_presets.large_trans;
params(135).z = z_presets.large_trans;
params(136).z = z_presets.large_trans;

%% Run alignment
% XY
try
    align_stack_xy
catch xy_error
    warning(xy_error.message)
    troubleshoot_xy
end

% Z
try
    align_stack_z
catch z_error
    warning(z_error.message)
    switch z_error.identifier
        case {'Z:LargeMatchError', 'Z:LargeAlignmentError'}
            plot_displacements(secB.z_matches)
        otherwise
            
    end
end