%% Configuration
% Wafer and sections
waferpath('/mnt/data0/ashwin/07122012/S2-W001')
info = get_path_info(waferpath);
wafer = info.wafer;
sec_nums = info.sec_nums;
sec_nums(103) = []; % skip

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

% S2-W001
params(5).xy.max_match_error = inf;
params(6).xy = xy_presets.grid_align;
params(7).xy.max_match_error = inf;
params(13).xy.max_match_error = inf;
params(14).xy = xy_presets.grid_align;
params(15).xy = xy_presets.gmm_filter;
params(15).xy.max_match_error = inf;
params(16).xy = xy_presets.gmm_filter;
params(17).xy.SURF.MetricThreshold = 9000;
params(17).xy.max_match_error = inf;
params(18).xy.max_match_error = inf;
params(19).xy.max_match_error = inf;
params(20).xy = xy_presets.grid_align;
params(20).xy.SURF.MetricThreshold = 8000;
params(20).xy.gmm_filter.matching.filter_method = 'gmm';
params(20).xy.gmm_filter.matching.filter_fallback = 'geomedian';
params(34).xy = xy_presets.grid_align;
params(40).xy.max_match_error = inf;
params(41).xy.max_match_error = inf;
params(51).xy.max_match_error = inf;
params(55).xy = xy_presets.grid_align;
params(59).xy = xy_presets.gmm_filter;
params(59).xy.SURF.MetricThreshold = 9000;
params(72).xy.max_match_error = inf;
params(105).xy = xy_presets.grid_align;
params(105).xy.SURF.MetricThreshold = 8000;
params(105).xy.gmm_filter.matching.filter_method = 'gmm';
params(105).xy.gmm_filter.matching.filter_fallback = 'geomedian';
params(118).xy.max_match_error = inf;
params(130).xy = xy_presets.grid_align;
params(131).xy.max_match_error = inf;
params(141).xy.max_match_error = inf;

%% Run alignment
try
    align_stack_xy
    align_stack_z
catch alignment_error
    troubleshoot
end