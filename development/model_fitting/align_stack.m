% Aligns a stack of sections.

%% Parameters
sec_nums = (100:149)';

% XY alignment
default.xy.scales = {'full', 1.0, 'rough', 0.07 * 0.78};
default.xy.SURF.MetricThreshold = 11000;

% Z alignment
default.z.scale = 0.35;
default.z.SURF.MetricThreshold = 10000;
default.z.NNR.MaxRatio = 0.6;
default.z.NNR.MatchThreshold = 1.0;
default.z.match_z.filter_outliers = false;
default.z.match_z.filter_secondpass = true;
default.z.second_pass_threshold = '2x';
default.z.alignment_method = 'lsq'; % 'lsq' or 'cpd'

% Initialize parameters with defaults
for s=1:length(sec_nums); params(s) = default; end

% Fallback preset for when Z matching fails
z_fallback = default.z;
z_fallback.scale = 0.125;
z_fallback.SURF.MetricThreshold = 2000;

% Custom per-section parameters
params(7).z = z_fallback;
params(8).z = z_fallback;
params(9).z = z_fallback;
params(12).z = z_fallback;
params(14).z = z_fallback;
params(15).z = z_fallback;

%% Rough & XY Alignment
xy_time = tic;
secs = cell(size(sec_nums));
for s = 1:length(secs)
    fprintf('=== Aligning section %d (<strong>%d/%d</strong>) in XY\n', sec_nums(s), s, length(secs))
    
    % Parameters
    xy = params(s).xy;
    
    % Load section
    sec = load_section(sec_nums(s), 'scales', xy.scales);
    
    if s > 1
        try
            % Align overviews
            sec.overview.alignment = align_overviews(secs{s - 1}, sec);
        catch
            % Fallback to the same alignment as the previous section
            sec.overview.alignment = secs{s - 1}.overview.alignment;
        end
        secs{s - 1} = imclear_sec(secs{s - 1}, 'overview');
    end

    % Rough alignment
    sec.alignments.rough = rough_align(sec);

    % Detect XY features
    sec.features.xy = detect_features(sec, 'regions', 'xy', xy.SURF);

    % Clear tile images
    sec = imclear_sec(sec, 'tiles');
    
    % Match XY features
    sec.xy_matches = match_xy(sec);

    % Align XY
    sec.alignments.xy = align_xy(sec);
    
    % Save
    secs{s} = sec;
    clear sec
end
secs{end} = imclear_sec(secs{end}, 'overview');
cprintf('*text', '==== Finished XY alignment in %.2fs.\n\n', toc(xy_time));

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
    
    % Load tiles at Z feature detection scale
    if ~isfield(secA.tiles, 'z') || secA.tiles.z.scale ~= z.scale
        secA = load_tileset(secA, 'z', z.scale);
    end
    secB = load_tileset(secB, 'z', z.scale);
    
    % Detect features in overlapping regions
    secA.features.z = detect_features(secA, 'regions', sec_bb(secB, 'xy'), 'alignment', 'z', 'detection_scale', z.scale, z.SURF);
    secB.features.z = detect_features(secB, 'regions', sec_bb(secA, 'z'), 'alignment', 'xy', 'detection_scale', z.scale, z.SURF);
    
    % Clear tile images in previous section
    secA = imclear_sec(secA, 'tiles');
    
    % Match features
    secB.z_matches = match_z(secA, secB, z.match_z, z.NNR);
    
    % Check for bad matching
    if secB.z_matches.meta.avg_error > 500
        stopped_at = s;
        error('[sec %d/%d]: Error before alignment is too large for good alignment. Check Z matches and/or try using fallback parameters.', s, length(secs))
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
    if secB.alignments.z.meta.avg_post_error > 15
        stopped_at = s;
        error('[sec %d/%d]: Error after alignment is too large for good alignment. Check Z matches.', s, length(secs))
    end
    
    % Save
    secs{s - 1} = secA;
    secs{s} = secB;
    clear secA secB
end
secs{end} = imclear_sec(secs{end}, 'tiles');
cprintf('*text', '==== Finished Z alignment in %.2fs.\n\n', toc(z_time));

%% Render
render_region

return
%% Troubleshooting
s = 6;
secA = secs{s - 1};
secB = secs{s};

%% Troubleshooting: Plot matches
M = merge_match_sets(secB.z_matches);
plot_section(secA, 'z')
plot_section(secB, 'xy')
plot_matches(M.A, M.B)
title(sprintf('Matches (secs %d <-> %d) | Error: %fpx / match', secA.num, secB.num, secB.z_matches.meta.avg_error))

%% Troubleshooting: Plot alignment
plot_section(secA, 'z')
plot_section(secB, 'z')
title(sprintf('Secs %d <-> %d | Error: %fpx -> %fpx / match', secA.num, secB.num, secB.alignments.z.meta.avg_prior_error, secB.alignments.z.meta.avg_post_error))