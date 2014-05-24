%% Section parameters
% Defaults: XY alignment
defaults.xy.scales = {'full', 1.0, 'rough', 0.07 * 0.78};
defaults.xy.SURF.MetricThreshold = 11000; % for full res tiles

% Defaults: Z alignment
defaults.z.rel_to = -1; % relative section to align to
defaults.z.matching.method = 'gmm';
% Tile scaling: 0.125x
defaults.z.scale = 0.125;
defaults.z.SURF.MetricThreshold = 2000;
% Matching: NNR
defaults.z.matching.NNR.MaxRatio = 0.6;
defaults.z.matching.NNR.MatchThreshold = 1.0;
% Matching: GMM
defaults.z.matching.inlier_cluster = 'geomedian';
% Alignment
defaults.z.alignment_method = 'cpd'; % 'lsq', 'cpd' or 'fixed'
% Quality control checks
defaults.z.max_match_error = 1000; % avg error after Z matching
defaults.z.max_aligned_error = 50; % avg error after alignment
defaults.z.ignore_error = false; % still throws warning

% Initialize parameters with defaults
params = repmat(defaults, max(sec_nums), 1);

% Custom per-section parameters
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

% Presets
ignore_z_error = defaults.z;
ignore_z_error.ignore_error = true;
fixed_z = defaults.z;
fixed_z.alignment_method = 'fixed';
rel_to_2previous = defaults.z;
rel_to_2previous.rel_to = -2;
rel_to_3previous = defaults.z;
rel_to_3previous.rel_to = -3;
large_trans = defaults.z;
large_trans.max_match_error = inf;
large_trans.matching.inlier_cluster = 'smallest_var';
manual_matching = defaults.z;
manual_matching.matching.method = 'manual';
manual_matching.max_aligned_error = 250;
low_res = defaults.z;
low_res.scale = 0.075;
low_res.SURF.MetricThreshold = 1000;