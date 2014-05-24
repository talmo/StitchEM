% Aligns a stack of sections.

%% Parameters
% Stack
info = get_path_info(waferpath);
sec_nums = info.sec_nums;

% Run parameters
overwrite_secs = false; % errors out if the current section was already aligned
stop_after = 'z'; % 'xy', or 'z'

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
% Tile scaling: 0.25x
% default.z.scale = 0.25;
% default.z.SURF.MetricThreshold = 7500;
% Tile scaling: 0.45x
%default.z.scale = 0.45;
%default.z.SURF.MetricThreshold = 15000;
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

% S2-W002:
% Bad rotation in section 1:
%params(2).z = fixed_z;
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

% params(14).z = rel_to_2previous; % tested
% params(17).z.matching.method = 'manual';
% %params(17).z = fixed_z; % tested
% %params(18).z = fixed_z; % tested
% %params(20).z = fixed_z; % tested
% %params(71).z = fixed_z; % tested
% params(72).z = rel_to_2previous; % tested
% params(87).z.max_aligned_error = 55; % 87 is rotated
% %params(88).z = fixed_z; % tested
% params(89).z = rel_to_2previous; % tested
% params(134).z.max_match_error = inf; % tested
% params(135).z.max_match_error = inf; % tested
% params(138).z = large_trans; % tested
% params(138).z.max_aligned_error = 75; % tested - but is this good?
% params(139).z = large_trans; % tested
% params(140).z = large_trans; % tested
% params(140).z.scale = 0.075; % tested
% params(140).z.SURF.MetricThreshold = 1000; % tested
% params(141).z = large_trans; % tested
% params(141).z.max_aligned_error = 75; % tested
% params(142).z = large_trans; % tested
% params(143).z = large_trans; % tested
% params(144).z = large_trans; % tested
% params(145).z = large_trans; % tested
% params(146).z = large_trans; % tested
% params(146).z.max_aligned_error = 100; % tested
% params(147).z = large_trans; % tested
% params(148).z = large_trans; % tested
% params(148).z.max_aligned_error = 100; % tested
% params(149).z = large_trans;
% params(149).z.max_aligned_error = 150; % tested


% S2-W003:
% Section 72 is rotated by quite a bit, but 73 goes back to normal
%[params(72:73).z] = deal(ignore_z_error);

%% Rough & XY Alignment
if ~exist('params', 'var'); error('The ''params'' variable does not exist. Load parameters before doing XY alignment.'); end
if ~exist('secs', 'var'); secs = cell(length(sec_nums), 1); end

disp('==== <strong>Started XY alignment</strong>.')
start_on = 1;
if exist('stopped_on', 'var')
    start_on = stopped_on;
    fprintf('<strong>Resuming XY alignment on section %d/%d.</strong> Clear ''stopped_on'' to reset.\n', start_on, length(sec_nums))
end
for s = start_on:length(secs)
    stopped_on = s;
    sec_timer = tic;
    
    % Parameters
    xy_params = params(sec_nums(s)).xy;
    
    fprintf('=== Aligning section %d (<strong>%d/%d</strong>) in XY\n', sec_nums(s), s, length(secs))
    if ~isempty(secs{s}) && isfield(secs{s}.alignments, 'xy')
        if overwrite_secs
            warning('Section %s is already aligned, but will be overwritten.\n', secs{s}.name)
        else
            error('Section %s is already aligned.', secs{s}.name)
        end
    end
    
    % Load section
    sec = load_section(sec_nums(s), 'scales', xy_params.scales);

    % Rough alignment
    sec.alignments.rough_xy = rough_align_xy(sec);

    % Detect XY features
    sec.features.xy = detect_features(sec, 'regions', 'xy', xy_params.SURF);
    
    % Match XY features
    sec.xy_matches = match_xy(sec);

    % Align XY
    sec.alignments.xy = align_xy(sec);
    
    % Clear images and XY features to save memory
    sec = imclear_sec(sec);
    sec.features.xy.tiles = [];
    
    % Save
    sec.params.xy = xy_params;
    sec.runtime.xy.time_elapsed = toc(sec_timer);
    sec.runtime.xy.timestamp = datestr(now);
    secs{s} = sec;
    clear sec
end
clear stopped_on

% Save to cache
disp('=== Saving sections to disk.');
save(sprintf('%s_secs%d-%d_xy_aligned.mat', secs{1}.wafer, secs{1}.num, secs{end}.num), 'secs', '-v7.3')

total_xy_time = sum(cellfun(@(sec) sec.runtime.xy.time_elapsed, secs));
fprintf('==== <strong>Finished XY alignment in %.2fs (%.2fs / section)</strong>.\n\n', total_xy_time, total_xy_time / length(secs));

if strcmpi(stop_after, 'xy')
    fprintf('Stopping after XY alignment as per parameters.\n')
    return
end

%% Z Alignment
if ~exist('params', 'var'); error('The ''params'' variable does not exist. Load parameters before doing Z alignment.'); end
if ~exist('secs', 'var'); error('The ''secs'' variable does not exist. Run XY alignment or load a saved stack before doing Z alignment.'); end

disp('==== <strong>Started Z alignment</strong>.')
start_on = 1;
if exist('stopped_on', 'var')
    start_on = stopped_on;
    fprintf('<strong>Resuming Z alignment on section %d/%d.</strong>\n', start_on, length(sec_nums))
end
% Align section pairs
for s = start_on:length(secs)
    stopped_on = s;
    sec_timer = tic;
    
    fprintf('=== Aligning %s (<strong>%d/%d</strong>) in Z\n', secs{s}.name, s, length(secs))
    
    % Parameters
    z_params = params(sec_nums(s)).z;
    
    % Keep first section fixed
    if s == 1
        secs{s}.alignments.z = fixed_alignment(secs{s}, 'xy');
        secs{s}.runtime.z.time_elapsed = toc(sec_timer);
        secs{s}.runtime.z.timestamp = datestr(now);
        continue
    end
    
    % We're aligning section B to A
    secA = secs{s + z_params.rel_to};
    secB = secs{s};
    
    % Compose with previous Z alignment
    rel_alignments = {'prev_z', 'z'};
    if ~isfield(secA.alignments, 'prev_z');
        rel_alignments = 'z'; % fixed sections have no previous Z alignment
    end
    secB.alignments.prev_z = compose_alignments(secA, rel_alignments, secB, 'xy');
    
    % Keep fixed
    if strcmp(z_params.alignment_method, 'fixed')
        secB.alignments.z = fixed_alignment(secB, 'prev_z');
        secB.runtime.z.time_elapsed = toc(sec_timer);
        secB.runtime.z.timestamp = datestr(now);
        secs{s} = secB;
        continue
    end
    
    % Match features
    switch z_params.matching.method
        case 'gmm'
             % Load tile images
            if ~isfield(secA.tiles, 'z') || secA.tiles.z.scale ~= z_params.scale; secA = load_tileset(secA, 'z', z_params.scale); end
            if ~isfield(secB.tiles, 'z') || secB.tiles.z.scale ~= z_params.scale; secB = load_tileset(secB, 'z', z_params.scale); end

            % Detect features in overlapping regions
            secA.features.base_z = detect_features(secA, 'regions', sec_bb(secB, 'prev_z'), 'alignment', 'z', 'detection_scale', z_params.scale, z_params.SURF);
            secB.features.z = detect_features(secB, 'regions', sec_bb(secA, 'z'), 'alignment', 'prev_z', 'detection_scale', z_params.scale, z_params.SURF);
            
            % Match
            secB.z_matches = match_z_gmm(secA, secB, 'base_z', 'z', z_params.matching);
        case 'manual'
            secB.z_matches = select_z_matches(secA, secB);
    end
    
    % Check for bad matching
    if secB.z_matches.meta.avg_error > z_params.max_match_error && ~strcmp(z_params.matching.method, 'manual')
        msg = sprintf('[%s]: Error after matching is very large. This may be because the two sections are misaligned by a large rotation/translation or due to bad matching.', secB.name);
        if z_params.ignore_error
            warning(msg)
        else
            % All displacements
            plot_displacements(secB.z_matches.meta.all_displacements), hold on
            % Inlier displacements
            displacements = secB.z_matches.B.global_points - secB.z_matches.A.global_points;
            scatter(displacements(:,1), displacements(:,2), 'gx')
            title(sprintf('Displacements (secs %d <-> %d) | Error: %fpx / match | n = %d -> %d after filtering', secA.num, secB.num, secB.z_matches.meta.avg_error, length(secB.z_matches.meta.all_displacements), secB.z_matches.num_matches))
            error(msg)
        end
    end
    
    % Align
    switch z_params.alignment_method
        case 'lsq'
            % Least Squares
            secB.alignments.z = align_z_pair_lsq(secB);
        
        case 'cpd'
            % Coherent Point Drift
            secB.alignments.z = align_z_pair_cpd(secB);
    end
    
    % Check for bad alignment
    if secB.alignments.z.meta.avg_post_error > z_params.max_aligned_error
        msg = sprintf('[%s]: Error after alignment is very large. This may be because the two sections are misaligned by a large rotation/translation or due to bad matching.', secB.name);
        if z_params.ignore_error
            warning(msg)
        else
            % All displacements
            plot_displacements(secB.z_matches.meta.all_displacements), hold on
            % Inlier displacements
            displacements = secB.z_matches.B.global_points - secB.z_matches.A.global_points;
            scatter(displacements(:,1), displacements(:,2), 'gx')
            title(sprintf('Displacements (secs %d <-> %d) | Error: %fpx / match | n = %d -> %d after filtering', secA.num, secB.num, secB.z_matches.meta.avg_error, length(secB.z_matches.meta.all_displacements), secB.z_matches.num_matches))
            error(msg)
        end
    end
    
    % Clear tile images and features to save memory
    secA = imclear_sec(secA, 'tiles');
    secA.features.base_z.tiles = [];
    secB.features.z.tiles = [];
    
    % Save
    secB.params.z = z_params;
    secB.runtime.z.time_elapsed = toc(sec_timer);
    secB.runtime.z.timestamp = datestr(now);
    secs{s + z_params.rel_to} = secA;
    secs{s} = secB;
    clear secA secB
end
secs{end} = imclear_sec(secs{end});

% Save to cache
disp('=== Saving sections to disk.');
%save(sprintf('%s_secs%d-%d_z_aligned_lsq_0.125x.mat', secs{1}.wafer, secs{1}.num, secs{end}.num), 'secs', '-v7.3')
%save('control.mat', 'secs', '-v7.3')
save(sprintf('%s_secs%d-%d_z_aligned.mat', secs{1}.wafer, secs{1}.num, secs{end}.num), 'secs', '-v7.3')

total_z_time = sum(cellfun(@(sec) sec.runtime.z.time_elapsed, secs));
fprintf('==== <strong>Finished Z alignment in %.2fs (%.2fs / section)</strong>.\n\n', total_z_time, total_z_time / length(secs));

if strcmpi(stop_after, 'z')
    fprintf('Stopping after Z alignment as per parameters.\n')
    return
end

%% Render
render_region

return
%% Troubleshooting
s = 16;
secA = secs{s - 1};
secB = secs{s};

%% Troubleshooting: Plot features (secA)
feature_set = 'base_z';
pointsA = cell2mat(cellfun(@(t) t.global_points,  secA.features.(feature_set).tiles, 'UniformOutput', false));

plot_section(secA, secA.features.(feature_set).meta.base_alignment, 'r0.1');
plot_features(pointsA)

%% Troubleshooting: Plot features (secB)
feature_set = 'z';
pointsB = cell2mat(cellfun(@(t) t.global_points,  secB.features.(feature_set).tiles, 'UniformOutput', false));

plot_section(secB, secB.features.(feature_set).meta.base_alignment, 'g0.1');
plot_features(pointsB)

%% Troubleshooting: Plot matches
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'prev_z', 'g0.1')
plot_matches(secB.z_matches.A, secB.z_matches.B)
title(sprintf('Matches (secs %d <-> %d) | Error: %fpx / match | n = %d matches', secA.num, secB.num, secB.z_matches.meta.avg_error, secB.z_matches.num_matches))

%% Troubleshooting: Plot displacements
% All displacements
plot_displacements(secB.z_matches.meta.all_displacements), hold on
% Inlier displacements
displacements = secB.z_matches.B.global_points - secB.z_matches.A.global_points;
scatter(displacements(:,1), displacements(:,2), 'gx')
title(sprintf('Displacements (secs %d <-> %d) | Error: %fpx / match | n = %d -> %d after filtering', secA.num, secB.num, secB.z_matches.meta.avg_error, length(secB.z_matches.meta.all_displacements), secB.z_matches.num_matches))

%% Troubleshooting: Plot alignment
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'z', 'g0.1')
title(sprintf('Secs %d <-> %d | Error: %fpx -> %fpx / match | Method: %s', secA.num, secB.num, secB.alignments.z.meta.avg_prior_error, secB.alignments.z.meta.avg_post_error, secB.alignments.z.meta.method), 'Interpreter', 'none')
