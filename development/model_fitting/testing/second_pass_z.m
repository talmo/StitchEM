% Defaults: Z alignment
% Tile scaling: 0.125x
%default.z.scale = 0.125;
%default.z.SURF.MetricThreshold = 2000;
% Tile scaling: 0.25x
default.z.scale = 0.25;
default.z.SURF.MetricThreshold = 7500;
% Matching: NNR
default.z.matching.MaxRatio = 0.6;
default.z.matching.MatchThreshold = 1.0;
% Matching: GMM
default.z.matching.inlier_cluster = 'geomedian';
% Alignment
default.z.alignment_method = 'cpd'; % 'lsq' or 'cpd'
% Quality control checks
default.z.max_match_error = 1000; % avg error after Z matching
default.z.max_aligned_error = 50; % avg error after alignment

% Initialize parameters with defaults
for s=1:numel(secs); params(s) = default; end

% Custom per-section parameters
% Exampple:
% params(38).z.NNR.MaxRatio = 0.8;

% Section 72 is rotated by quite a bit, but 73 goes back to normal
params(72).z.max_match_error = inf;
params(72).z.max_aligned_error = inf;
params(73).z.max_match_error = inf;
params(73).z.max_aligned_error = inf;

%% Z Alignment
if ~exist('params', 'var'); error('The ''params'' variable does not exist. Load parameters before doing Z alignment.'); end

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
        secs{1}.alignments.z2 = fixed_alignment(secs{1}, 'z');
        continue
    end
    
    % We're aligning section B to A
    secA = secs{s - 1};
    secB = secs{s};
    
    % Load tile images
    if ~isfield(secA.tiles, 'z2') || secA.tiles.z2.scale ~= z.scale; secA = load_tileset(secA, 'z2', z.scale); end
    if ~isfield(secB.tiles, 'z2') || secB.tiles.z2.scale ~= z.scale; secB = load_tileset(secB, 'z2', z.scale); end
    
    % Compose with previous Z alignment
    rel_alignments = {'prev_z2', 'z2'};
    if secA.num == 1
        rel_alignments = 'z2'; % first section has no previous Z alignment
    end
    secB.alignments.prev_z2 = compose_alignments(secA, rel_alignments, secB, 'z');
    
    % Detect features in overlapping regions
    secA.features.base_z2 = detect_features(secA, 'regions', sec_bb(secB, 'prev_z2'), 'alignment', 'z2', 'detection_scale', z.scale, z.SURF);
    secB.features.z2 = detect_features(secB, 'regions', sec_bb(secA, 'z2'), 'alignment', 'prev_z2', 'detection_scale', z.scale, z.SURF);
    
    % Match features
    secB.z_matches2 = match_z_gmm(secA, secB, 'base_z2', 'z2', z.matching);
    
    % Check for bad matching
    if secB.z_matches2.meta.avg_error > z.max_match_error
        error('[sec %d/%d]: Error after matching is very large. This may be because the two sections are misaligned by a large rotation/translation or due to bad matching.', s, length(secs))
    end
    
    % Align
    switch z.alignment_method
        case 'lsq'
            % Least Squares
            secB.alignments.z2 = align_z_pair_lsq(secB, secB.z_matches2);
        
        case 'cpd'
            % Coherent Point Drift
            secB.alignments.z2 = align_z_pair_cpd(secB, secB.z_matches2);
    end
    
    % Check for bad alignment
    if secB.alignments.z.meta.avg_post_error > z.max_aligned_error
        error('[sec %d/%d]: Error after alignment is very large. This may be because the two sections are misaligned by a large rotation/translation or due to bad matching.', s, length(secs))
    end
    
    % Clear tile images and features to save memory
    secA = imclear_sec(secA, 'tiles');
    secA.features.base_z2.tiles = [];
    secB.features.z2.tiles = [];
    
    % Save
    secB.params.z2 = z;
    secs{s - 1} = secA;
    secs{s} = secB;
    clear secA secB
end
secs{end} = imclear_sec(secs{end});

% Save to cache
disp('=== Saving sections to disk.');
save(sprintf('%s_secs%d-%d_z_aligned2.mat', secs{1}.wafer, secs{1}.num, secs{end}.num), 'secs', '-v7.3')

fprintf('==== <strong>Finished Z alignment in %.2fs</strong>.\n\n', toc(z_time));

%% Troubleshooting
s = 72;
secA = secs{s - 1};
secB = secs{s};

%% Troubleshooting: Plot features (secA)
feature_set = 'base_z2';
pointsA = cell2mat(cellfun(@(t) t.global_points,  secA.features.(feature_set).tiles, 'UniformOutput', false));

plot_section(secA, secA.features.(feature_set).meta.base_alignment);
plot_features(pointsA)

%% Troubleshooting: Plot features (secB)
feature_set = 'z2';
pointsB = cell2mat(cellfun(@(t) t.global_points,  secB.features.(feature_set).tiles, 'UniformOutput', false));

plot_section(secB, secB.features.(feature_set).meta.base_alignment);
plot_features(pointsB)

%% Troubleshooting: Plot matches
plot_section(secA, 'z2', 'r0.1')
plot_section(secB, 'prev_z2', 'g0.1')
plot_matches(secB.z_matches2.A, secB.z_matches2.B)
title(sprintf('Matches (secs %d <-> %d) | Error: %fpx / match | n = %d matches', secA.num, secB.num, secB.z_matches2.meta.avg_error, secB.z_matches2.num_matches))

%% Troubleshooting: Plot displacements
% All displacements
plot_displacements(secB.z_matches2.meta.all_displacements), hold on
% Inlier displacements
displacements = secB.z_matches2.B.global_points - secB.z_matches2.A.global_points;
scatter(displacements(:,1), displacements(:,2), 'gx')
title(sprintf('Displacements (secs %d <-> %d) | Error: %fpx / match | n = %d -> %d after filtering', secA.num, secB.num, secB.z_matches.meta.avg_error, length(secB.z_matches.meta.all_displacements), secB.z_matches.num_matches))

%% Troubleshooting: Plot alignment
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'z', 'g0.1')
title(sprintf('Secs %d <-> %d | Error: %fpx -> %fpx / match | Method: %s', secA.num, secB.num, secB.alignments.z.meta.avg_prior_error, secB.alignments.z.meta.avg_post_error, secB.alignments.z.meta.method), 'Interpreter', 'none')
