% Aligns a stack of sections.

%% Parameters
% Sections to align
sec_nums = (1:5)';

% Defaults: XY alignment
default.xy.scales = {'full', 1.0, 'rough', 0.07 * 0.78};
default.xy.SURF.MetricThreshold = 11000;

% Defaults: Z alignment
default.z.rough_align.overview_scale = 0.78;
default.z.scale = 0.125;
default.z.SURF.MetricThreshold = 2000;
default.z.NNR.MaxRatio = 0.6;
default.z.NNR.MatchThreshold = 1.0;
default.z.match_z.filter_outliers = false;
default.z.match_z.filter_secondpass = true;
default.z.match_z.second_pass_threshold = '1.25x';
default.z.alignment_method = 'cpd'; % 'lsq' or 'cpd'
default.z.max_match_error = 1000;
default.z.max_aligned_error = 50;

% Initialize parameters with defaults
for s=1:length(sec_nums); params(s) = default; end

% Fallback preset for when Z matching fails
%z_fallback = default.z;
%z_fallback.scale = 0.125;
%z_fallback.SURF.MetricThreshold = 2000;

% Custom per-section parameters
% params(38).z.match_z.second_pass_threshold = '1.0x';
% params(38).z.max_aligned_error = 150;
% params(39).z.max_aligned_error = 65;
% params(40).z.max_match_error = 1100;
% params(40).z.max_aligned_error = 100;
% params(41).z.max_aligned_error = 100;
% params(42).z.max_aligned_error = 100;
% for s=43:length(sec_nums); params(s).z.max_aligned_error = 100; end
% for s=47:length(sec_nums); params(s).z.max_match_error = 1500; end
% for s=47:length(sec_nums); params(s).z.max_aligned_error = 150; end
% for s=67:length(sec_nums); params(s).z.max_aligned_error = 200; end
%% Rough & XY Alignment
xy_time = tic;
if ~exist('stopped_at', 'var'); stopped_at = NaN; end
start_at_sec = max(1, stopped_at);
secs = cell(size(sec_nums));
for s = start_at_sec:length(secs)
    fprintf('=== Aligning section %d (<strong>%d/%d</strong>) in XY\n', sec_nums(s), s, length(secs))
    
    % Parameters
    xy = params(s).xy;
    
    % Load section
    sec = load_section(sec_nums(s), 'scales', xy.scales);

    % Rough alignment
    sec.alignments.rough_xy = rough_align_xy(sec);

    % Detect XY features
    sec.features.xy = detect_features(sec, 'regions', 'xy', xy.SURF);

    % Clear images
    sec = imclear_sec(sec);
    
    % Match XY features
    sec.xy_matches = match_xy(sec);

    % Align XY
    sec.alignments.xy = align_xy(sec);
    
    % Save
    sec.params.xy = xy;
    secs{s} = sec;
    clear sec
end
cprintf('*text', '==== Finished XY alignment in %.2fs.\n\n', toc(xy_time));
clear stopped_at
save(sprintf('%s_secs%d-%d_xy_aligned.mat', secs{1}.wafer, secs{1}.num, secs{end}.num), 'secs', '-v7.3')
%% Z Alignment
z_time = tic;

% Resume where we stopped if we get an error
if ~exist('stopped_at', 'var'); stopped_at = NaN; end
start_at_sec = max(1, stopped_at);

% Align section pairs
for s = start_at_sec:length(secs)
    fprintf('=== Aligning section %d (<strong>%d/%d</strong>) in Z\n', secs{s}.num, s, length(secs))
    
    % Parameters
    z = params(s).z;
    
    % Keep first section fixed
    if s == 1
        disp('Keeping section fixed with respect to XY alignment.')
        secs{s}.alignments.z = secs{s}.alignments.xy;
        continue
    end
    
    % We're aligning section B to A
    secA = secs{s - 1};
    secB = secs{s};
    
    % Load images
    if ~isfield(secA.overview.img) || isempty(secA.overview.img) || secA.overview.scale ~= z.rough_align.overview_scale; secA = load_overview(secA, z.rough_align.overview_scale); end
    if ~isfield(secB.overview.img) || isempty(secB.overview.img) || secB.overview.scale ~= z.rough_align.overview_scale; secB = load_overview(secB, z.rough_align.overview_scale); end
    if ~isfield(secA.tiles, 'z') || secA.tiles.z.scale ~= z.scale; secA = load_tileset(secA, 'z', z.scale); end
    if ~isfield(secB.tiles, 'z') || secB.tiles.z.scale ~= z.scale; secB = load_tileset(secB, 'z', z.scale); end

    % Register overviews
    try
        secB.overview.alignment = align_overviews(secA, secB);
    catch
        % Fallback to the same alignment as the previous section
        fprintf('Could not align overview of section %d to %d.\n', secB.num, secA.num)
        secB.overview.alignment = secA.overview.alignment;
    end
    
    % Do rough alignment in Z based on overviews
    secB.rough_z = rough_align_z(secA, secB, z.rough_align);
    
    % Detect features in overlapping regions
    secA.features.z = detect_features(secA, 'regions', sec_bb(secB, 'rough_z'), 'alignment', 'z', 'detection_scale', z.scale, z.SURF);
    secB.features.z = detect_features(secB, 'regions', sec_bb(secA, 'z'), 'alignment', 'rough_z', 'detection_scale', z.scale, z.SURF);
    
    % Match features
    secB.z_matches = match_z(secA, secB, z.match_z, z.NNR);
    
    % Check for bad matching
    if secB.z_matches.meta.avg_error > z.max_match_error
        stopped_at = s;
        error('[sec %d/%d]: Error after matching is too large for good alignment. There are probably too many outliers.', s, length(secs))
    end
    
    % Align
    switch z.alignment_method
        case 'lsq'
            % Least Squares
            secB.alignments.z = align_z_pair_lsq(secB, secB.z_matches);
        
        case 'cpd'
            % Coherent Point Drift
            secB.alignments.z = align_z_pair_cpd(secB, secB.z_matches);
    end
    
    % Check for bad alignment
    if secB.alignments.z.meta.avg_post_error > z.max_aligned_error
        stopped_at = s;
        error('[sec %d/%d]: Error after alignment is too large for good alignment. Check Z matches.', s, length(secs))
    end
    
    % Clear tile images in previous section
    secA = imclear_sec(secA, 'tiles');
    
    % Save
    secB.params.z = z;
    secs{s - 1} = secA;
    secs{s} = secB;
    clear secA secB
end
secs{end} = imclear_sec(secs{end});
cprintf('*text', '==== Finished Z alignment in %.2fs.\n\n', toc(z_time));

%% Render
render_region

return
%% Troubleshooting
s = 50;
secA = secs{s - 1};
secB = secs{s};

%% Troubleshooting: Plot matches
M = merge_match_sets(secB.z_matches);
plot_section(secA, 'z')
plot_section(secB, 'xy')
plot_matches(M.A, M.B)
title(sprintf('Matches (secs %d <-> %d) | Error: %fpx / match', secA.num, secB.num, secB.z_matches.meta.avg_error))

%% Troubleshooting: Plot displacements
plot_displacements(secB.z_matches.meta.all_displacements), hold on
scatter(secB.z_matches.meta.filtered_displacements(:,1), secB.z_matches.meta.filtered_displacements(:,2), 'gx')
title(sprintf('Displacements (secs %d <-> %d) | Error: %fpx / match | n = %d -> %d after filtering', secA.num, secB.num, secB.z_matches.meta.avg_error, length(secB.z_matches.meta.all_displacements), secB.z_matches.num_matches))

%% Troubleshooting: Plot alignment
plot_section(secA, 'z')
plot_section(secB, 'z')
title(sprintf('Secs %d <-> %d | Error: %fpx -> %fpx / match | Method: %s', secA.num, secB.num, secB.alignments.z.meta.avg_prior_error, secB.alignments.z.meta.avg_post_error, secB.alignments.z.meta.method), 'Interpreter', 'none')

