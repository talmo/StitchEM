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
    
    fprintf('=== Aligning %s (<strong>%d/%d</strong>) in XY\n', get_path_info(get_section_path(sec_nums(s)), 'name'), s, length(secs))
    if ~isempty(secs{s}) && isfield(secs{s}.alignments, 'xy')
        if overwrite_secs
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
