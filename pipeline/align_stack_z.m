%% Z Alignment
if ~exist('params', 'var'); error('The ''params'' variable does not exist. Load parameters before doing Z alignment.'); end
if ~exist('secs', 'var'); error('The ''secs'' variable does not exist. Run XY alignment or load a saved stack before doing Z alignment.'); end
if ~exist('status', 'var') || strcmp(status.step, 'finished_xy'); status.step = 'z'; status.section = 1; end
if ~strcmp(status.step, 'z'); disp('<strong>Skipping Z alignment.</strong> Clear ''status'' to reset.'), return; end

if status.section == 1
    disp('==== <strong>Started Z alignment</strong>.')
else
    fprintf('==== <strong>Resuming Z alignment on section %d/%d.</strong> Clear ''status'' to reset.\n', status.section, length(sec_nums))
end
% Align section pairs
for s = status.section:length(sec_nums)
    status.section = s; sec_timer = tic;
    fprintf('=== Aligning %s (<strong>%d/%d</strong>) in Z\n', secs{s}.name, s, length(sec_nums))
    
    % Parameters
    z_params = params(sec_nums(s)).z;
    
    % Check for existing alignment
    if isfield(secs{s}.alignments, 'z') && ~z_params.overwrite
        error('Z:AlignedSecNotOverwritten', 'Section is already Z aligned. Set its ''overwrite'' parameter to true to overwrite alignment.')
    end
    
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
    switch z_params.matching_mode
        case 'auto'
             % Load tile images
            if ~isfield(secA.tiles, 'z') || secA.tiles.z.scale ~= z_params.scale; secA = load_tileset(secA, 'z', z_params.scale); end
            if ~isfield(secB.tiles, 'z') || secB.tiles.z.scale ~= z_params.scale; secB = load_tileset(secB, 'z', z_params.scale); end

            % Detect features in overlapping regions
            secA.features.base_z = detect_features(secA, 'regions', sec_bb(secB, 'prev_z'), 'alignment', 'z', 'detection_scale', z_params.scale, z_params.SURF);
            secB.features.z = detect_features(secB, 'regions', sec_bb(secA, 'z'), 'alignment', 'prev_z', 'detection_scale', z_params.scale, z_params.SURF);
            
            % Match
            secB.z_matches = match_z(secA, secB, 'base_z', 'z', z_params.matching);
        case 'manual'
            secB.z_matches = select_z_matches(secA, secB);
    end
    
    % Check for bad matching
    if secB.z_matches.meta.avg_error > z_params.max_match_error && ~strcmp(z_params.matching_mode, 'manual')
        msg = sprintf('[%s]: Error after matching is very large. This may be because the two sections are misaligned by a large rotation/translation or due to bad matching.', secB.name);
        if z_params.ignore_error
            warning('Z:LargeMatchError', msg)
        else
            error('Z:LargeMatchError', msg)
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
            warning('Z:LargeAlignmentError', msg)
        else
            error('Z:LargeAlignmentError', msg)
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
status.step = 'finished_z';

% Save to cache
disp('=== Saving sections to disk.'); save_timer = tic;
filename = sprintf('%s_Secs%d-%d_z_aligned.mat', secs{1}.wafer, secs{1}.num, secs{end}.num);
save(get_new_path(fullfile(cachepath, filename)), 'secs', 'status', '-v7.3')
fprintf('Saved to: %s [%.2fs]\n', fullfile(cachepath, filename), toc(save_timer))

total_z_time = sum(cellfun(@(sec) sec.runtime.z.time_elapsed, secs));
fprintf('==== <strong>Finished Z alignment in %.2fs (%.2fs / section)</strong>.\n\n', total_z_time, total_z_time / length(secs));
