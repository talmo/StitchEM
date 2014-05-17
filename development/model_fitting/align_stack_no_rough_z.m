% Aligns a stack of sections.

%% Parameters
% Sections to align
sec_nums = (1:100)';

% Defaults: XY alignment
default.xy.scales = {'full', 1.0, 'rough', 0.07 * 0.78};
default.xy.SURF.MetricThreshold = 11000; % for full res tiles

% Defaults: Z alignment
% Tile scaling: 0.125x
default.z.scale = 0.125;
default.z.SURF.MetricThreshold = 2000;
% Tile scaling: 0.25x
% default.z.scale = 0.25;
% default.z.SURF.MetricThreshold = 7500;
% Matching: NNR
default.z.matching.MaxRatio = 0.6;
default.z.matching.MatchThreshold = 1.0;
% Matching: GMM
default.z.matching.inlier_cluster = 'geomedian';
% Alignment
default.z.alignment_method = 'cpd'; % 'lsq' or 'cpd'
% Quality control checks
default.z.max_match_error = inf; % avg error after Z matching
default.z.max_aligned_error = 50; % avg error after alignment

% Initialize parameters with defaults
for s=1:length(sec_nums); params(s) = default; end

% Custom per-section parameters
% Exampple:
% params(38).z.NNR.MaxRatio = 0.8;
%params(26).z.max_match_error = 1200;

%% Rough & XY Alignment
xy_time = tic;
disp('==== <strong>Started XY alignment</strong>.')
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
    
    % Match XY features
    sec.xy_matches = match_xy(sec);

    % Align XY
    sec.alignments.xy = align_xy(sec);
    
    % Clear images and XY features to save memory
    sec = imclear_sec(sec);
    sec.features.xy.tiles = [];
    
    % Save
    sec.params.xy = xy;
    secs{s} = sec;
    clear sec
end
clear stopped_at

% Save to cache
disp('=== Saving sections to disk.');
save(sprintf('%s_secs%d-%d_xy_aligned.mat', secs{1}.wafer, secs{1}.num, secs{end}.num), 'secs', '-v7.3')

fprintf('==== <strong>Finished XY alignment in %.2fs</strong>.\n\n', toc(xy_time));
%% Z Alignment
z_time = tic;
disp('==== <strong>Started Z alignment</strong>.')

% Resume where we stopped if we get an error
if ~exist('stopped_at', 'var'); stopped_at = NaN; end
start_at_sec = max(1, stopped_at);

% Align section pairs
for s = start_at_sec:length(secs)
    fprintf('=== Aligning section %d (<strong>%d/%d</strong>) in Z\n', secs{s}.num, s, length(secs))
    stopped_at = s;
    
    % Parameters
    z = params(s).z;
    
    % Keep first section fixed
    if s == 1
        disp('Keeping section fixed with respect to XY alignment.')
        alignment.tforms = secs{1}.alignments.xy.tforms;
        alignment.rel_tforms = repmat({affine2d()}, size(alignment.tforms));
        alignment.rel_to = 'xy';
        alignment.meta.method = 'fixed';
        alignment.meta.avg_prior_error = NaN;
        alignment.meta.avg_post_error = NaN;
        secs{1}.alignments.z = alignment;
        continue
    end
    
    % We're aligning section B to A
    secA = secs{s - 1};
    secB = secs{s};
    
    % Load images
    if ~isfield(secA.tiles, 'z') || secA.tiles.z.scale ~= z.scale; secA = load_tileset(secA, 'z', z.scale); end
    if ~isfield(secB.tiles, 'z') || secB.tiles.z.scale ~= z.scale; secB = load_tileset(secB, 'z', z.scale); end
    
    % Compose with previous Z alignment
    rel_to_alignments = {'prev_z', 'z'}; % which alignments on previous section
    base_alignment = 'xy'; % which alignment on this section
    secB.alignments.prev_z.rel_to_sec = secA.num;
    secB.alignments.prev_z.rel_to_alignments = rel_to_alignments;
    rel_tforms = repmat({affine2d()}, size(secB.alignments.(base_alignment).tforms));
    for i = 1:numel(rel_to_alignments)
        rel_alignment = rel_to_alignments{i};
        if isfield(secA.alignments, rel_alignment)
            rel_tforms = compose_tforms(rel_tforms, secA.alignments.(rel_alignment).rel_tforms);
        end
    end
    secB.alignments.prev_z.rel_tforms = rel_tforms;
    secB.alignments.prev_z.rel_to = base_alignment;
    secB.alignments.prev_z.tforms = compose_tforms(secB.alignments.(base_alignment).tforms, rel_tforms);
    
    % Detect features in overlapping regions
    secA.features.base_z = detect_features(secA, 'regions', sec_bb(secB, 'prev_z'), 'alignment', 'z', 'detection_scale', z.scale, z.SURF);
    secB.features.z = detect_features(secB, 'regions', sec_bb(secA, 'z'), 'alignment', 'prev_z', 'detection_scale', z.scale, z.SURF);
    
    % Match features
    secB.z_matches = match_z_gmm(secA, secB, 'base_z', 'z', z.matching);
    
    % Check for bad matching
    if secB.z_matches.meta.avg_error > z.max_match_error
        error('[sec %d/%d]: Error after matching is too large for good alignment. There are probably too many outliers.', s, length(secs))
    end
    
    % Align
    switch z.alignment_method
        case 'lsq'
            % Least Squares
            secB.alignments.z = align_z_pair_lsq(secB, secB.z_matches);
        
        case 'cpd'
            % Coherent Point Drift
            secB.alignments.z = align_z_pair_cpd(secB, secB.z_matches, 'prev_z');
    end
    
    % Check for bad alignment
    if secB.alignments.z.meta.avg_post_error > z.max_aligned_error
        error('[sec %d/%d]: Error after alignment is too large for good alignment. Check Z matches.', s, length(secs))
    end
    
    % Clear tile images and features to save memory
    secA = imclear_sec(secA, 'tiles');
    secA.features.base_z.tiles = [];
    secB.features.z.tiles = [];
    
    % Save
    secB.params.z = z;
    secs{s - 1} = secA;
    secs{s} = secB;
    clear secA secB
end
secs{end} = imclear_sec(secs{end});

% Save to cache
disp('=== Saving sections to disk.');
save(sprintf('%s_secs%d-%d_z_aligned.mat', secs{1}.wafer, secs{1}.num, secs{end}.num), 'secs', '-v7.3')

fprintf('==== <strong>Finished Z alignment in %.2fs</strong>.\n\n', toc(z_time));

%% Render
render_region

return
%% Troubleshooting
s = 2;
secA = secs{s - 1};
secB = secs{s};

%% Troubleshooting: Plot features (secA)
feature_set = 'base_z';
pointsA = cell2mat(cellfun(@(t) t.global_points,  secA.features.(feature_set).tiles, 'UniformOutput', false));

plot_section(secA, secA.features.(feature_set).meta.base_alignment);
plot_features(pointsA)

%% Troubleshooting: Plot features (secB)
feature_set = 'z';
pointsB = cell2mat(cellfun(@(t) t.global_points,  secB.features.(feature_set).tiles, 'UniformOutput', false));

plot_section(secB, secB.features.(feature_set).meta.base_alignment);
plot_features(pointsB)

%% Troubleshooting: Plot matches
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'prev_z', 'g0.1')
plot_matches(secB.z_matches.A, secB.z_matches.B)
title(sprintf('Matches (secs %d <-> %d) | Error: %fpx / match', secA.num, secB.num, secB.z_matches.meta.avg_error))

%% Troubleshooting: Plot displacements
plot_displacements(secB.z_matches.meta.all_displacements), hold on
displacements = secB.z_matches.B.global_points - secB.z_matches.A.global_points;
scatter(displacements(:,1), displacements(:,2), 'gx')
title(sprintf('Displacements (secs %d <-> %d) | Error: %fpx / match | n = %d -> %d after filtering', secA.num, secB.num, secB.z_matches.meta.avg_error, length(secB.z_matches.meta.all_displacements), secB.z_matches.num_matches))

%% Troubleshooting: Plot alignment
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'z', 'g0.1')
title(sprintf('Secs %d <-> %d | Error: %fpx -> %fpx / match | Method: %s', secA.num, secB.num, secB.alignments.z.meta.avg_prior_error, secB.alignments.z.meta.avg_post_error, secB.alignments.z.meta.method), 'Interpreter', 'none')
