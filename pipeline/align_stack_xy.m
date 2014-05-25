%% Rough & XY Alignment
if ~exist('params', 'var'); error('The ''params'' variable does not exist. Load parameters before doing alignment.'); end
if ~exist('secs', 'var'); secs = cell(length(sec_nums), 1); end
if ~exist('status', 'var'); status.step = 'xy'; status.section = 1; end
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
    if ~isempty(secs{s}) && isfield(secs{s}.alignments, 'xy')
        if xy_params.overwrite
            warning('Section is already aligned, but will be overwritten.')
        else
            error('Section is already aligned.')
        end
    end
    
    % Load section
    sec = load_section(sec_nums(s), 'scales', xy_params.scales);

    % Rough alignment
    sec.alignments.rough_xy = rough_align_xy(sec);

    % Detect XY features
    sec.features.xy = detect_features(sec, 'regions', 'xy', xy_params.SURF);
    
    % Match XY features
    sec.xy_matches = match_xy(sec, 'xy', xy_params.matching);
    
    % Check for bad matching
    if sec.xy_matches.meta.avg_error > xy_params.max_match_error
        msg = sprintf('[%s]: Error after matching is very large. This may be due to bad match filtering.', sec.name);
        if xy_params.ignore_error
            warning('XY:LargeMatchError', msg)
        else
            error('XY:LargeMatchError',msg)
        end
    end
    
    % Align XY
    sec.alignments.xy = align_xy(sec, xy_params.align);
    
    % Check for bad alignment
    if sec.alignments.xy.meta.avg_post_error > xy_params.max_aligned_error
        msg = sprintf('[%s]: Error after alignment is very large. This may be due to bad matching.', sec.name);
        if xy_params.ignore_error
            warning('Z:LargeAlignmentError', msg)
        else
            error('Z:LargeAlignmentError', msg)
        end
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
disp('=== Saving sections to disk.');
filename = sprintf('%s_Secs%d-%d_xy_aligned.mat', secs{1}.wafer, secs{1}.num, secs{end}.num);
save(get_new_path(fullfile(cachepath, filename)), 'secs', 'status', '-v7.3')

total_xy_time = sum(arrayfun(@(s) secs{s}.runtime.xy.time_elapsed, sec_nums));
fprintf('==== <strong>Finished XY alignment in %.2fs (%.2fs / section)</strong>.\n\n', total_xy_time, total_xy_time / length(secs));
