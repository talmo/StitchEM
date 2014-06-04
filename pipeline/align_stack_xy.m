%% Rough & XY Alignment
if ~exist('params', 'var'); error('The ''params'' variable does not exist. Load parameters before doing alignment.'); end
if ~exist('secs', 'var'); secs = cell(length(sec_nums), 1); end
if ~exist('status', 'var'); status = struct(); end
if ~isfield(status, 'step'); status.step = 'xy'; end
if ~isfield(status, 'section'); status.section = 1; end
if ~strcmp(status.step, 'xy'); disp('<strong>Skipping XY alignment.</strong> Clear ''status'' to reset.'), return; end

if status.section == 1
    disp('==== <strong>Started XY alignment</strong>.')
else
    fprintf('==== <strong>Resuming XY alignment on section %d/%d.</strong> Clear ''status'' to reset.\n', status.section, length(sec_nums))
end
for s = status.section:length(sec_nums)
    status.section = s;
    sec_timer = tic;
    
    % Parameters
    xy_params = params(sec_nums(s)).xy;
    
    fprintf('=== Aligning %s (<strong>%d/%d</strong>) in XY\n', get_path_info(get_section_path(sec_nums(s)), 'name'), s, length(sec_nums))
    
    % Check for overwrite
    if ~isempty(secs{s}) && isfield(secs{s}.alignments, 'xy')
        if xy_params.overwrite; warning('XY:AlignedSecOverwritten', 'Section is already aligned, but will be overwritten.')
        else error('XY:AlignedSecNotOverwritten', 'Section is already aligned.'); end
    end
    
    % Section structure
    if ~exist('sec', 'var') || sec.num ~= sec_nums(s)
        % Create a new section structure
        sec = load_section(sec_nums(s), 'skip_tiles', xy_params.skip_tiles, 'wafer_path', waferpath());
    else
        % Use section in the workspace
        disp('Using section that was already loaded. Clear ''sec'' to force section to be reloaded.')
    end
    
    % Load images
    if ~isfield(sec.tiles, 'full'); sec = load_tileset(sec, 'full', 1.0); end
    if ~isfield(sec.tiles, 'rough'); sec = load_tileset(sec, 'rough', xy_params.rough.overview_registration.tile_scale); end
    if isempty(sec.overview) || ~isfield(sec.overview, 'img') || isempty(sec.overview.img) ...
            || ~isfield(sec.overview, 'scale') || sec.overview.scale ~= xy_params.rough.overview_registration.overview_scale
        sec = load_overview(sec, xy_params.rough.overview_registration.overview_scale);
    end
    
    % Rough alignment
    sec.alignments.rough_xy = rough_align_xy(sec, xy_params.rough);

    % Detect XY features
    sec.features.xy = detect_features(sec, 'alignment', 'rough_xy', 'regions', 'xy', xy_params.features);
    
    % Match XY features
    sec.xy_matches = match_xy(sec, 'xy', xy_params.matching);
    
    % Check for bad matching
    if sec.xy_matches.meta.avg_error > xy_params.max_match_error
        msg = sprintf('[%s]: Error after matching is very large. This may be due to bad rough alignment or match filtering.', sec.name);
        id = 'XY:LargeMatchError';
        if xy_params.ignore_error; warning(id, msg); else error(id, msg); end
    elseif ~isempty(find_orphan_tiles(sec, 'xy'))
        msg = sprintf('[%s]: There are tiles with no matches to any other tiles.\n\tOrphan tiles: %s\n', sec.name, vec2str(find_orphan_tiles(sec, 'xy')));
        id = 'XY:OrphanTiles';
        if xy_params.ignore_error; warning(id, msg); else error(id, msg); end
    end
    
    % Align XY
    sec.alignments.xy = align_xy(sec, xy_params.align);
    
    % Check for bad alignment
    if sec.alignments.xy.meta.avg_post_error > xy_params.max_aligned_error
        msg = sprintf('[%s]: Error after alignment is very large. This may be due to bad matching.', sec.name);
        id = 'XY:LargeAlignmentError';
        if xy_params.ignore_error; warning(id, msg); else error(id, msg); end
    end
    
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
status.step = 'finished_xy';

% Save to cache
disp('=== Saving sections to disk.'); save_timer = tic;
filename = sprintf('%s_Secs%d-%d_xy_aligned.mat', secs{1}.wafer, secs{1}.num, secs{end}.num);
save(get_new_path(fullfile(cachepath, filename)), 'secs', 'status', '-v7.3')
fprintf('Saved to: %s [%.2fs]\n', fullfile(cachepath, filename), toc(save_timer))

total_xy_time = sum(cellfun(@(sec) sec.runtime.xy.time_elapsed, secs));
fprintf('==== <strong>Finished XY alignment in %.2fs (%.2fs / section)</strong>.\n\n', total_xy_time, total_xy_time / length(secs));
