fprintf('=== <strong>Troubleshooting XY error</strong>: %s (%d/%d)\n', sec.name, status.section, length(secs))

%% Matching
% Get matches
last_xy_matches = sec.xy_matches;

if ~isfield(last_xy_matches, 'outliers')
    % Redetect matches with same parameters but keep outliers
    last_xy_matches = match_xy(sec, 'xy', xy_params.matching, 'keep_outliers', true, 'verbosity', 0);
end

% Show matching statistics
disp('== <strong>Matching</strong>:')
fprintf('<strong>NNR</strong>: %f px/match (n = %d)\n', last_xy_matches.meta.avg_nnr_error, last_xy_matches.meta.num_nnr_matches)
fprintf('<strong>Inliers</strong>: %f px/match (n = %d)\n', last_xy_matches.meta.avg_error, last_xy_matches.num_matches)
fprintf('<strong>Outliers</strong>: %f px/match (n = %d)\n', last_xy_matches.meta.avg_outlier_error, last_xy_matches.meta.num_outliers)

% Per tile:
% tile_stats = tile_match_stats(last_xy_matches, sec.grid);
% disp('<strong>Matches per tile:</strong>')
% disp(tile_stats.num_matches)
% disp('<strong>Match error before alignment per tile:</strong>')
% disp(tile_stats.match_error)
% if any(tile_stats.match_error > xy_params.max_match_error)
%     fprintf('<strong>Tiles exceeding max_match_error</strong>: %s\n', vec2str(find(tile_stats.match_error > xy_params.max_match_error)))
% end

disp('Check xy_params.matching for info on parameters used.')
   
%% Alignment
disp('== <strong>Alignment</strong>:')
% Check if section has alignment
last_alignment = [];
if (exist('xy_error', 'var') && strcmp(xy_error.identifier, 'XY:LargeMatchError')) || ...
        ~isfield(sec.alignments, 'xy')
    % Try to align anyway
    try
        last_alignment = align_xy(sec, xy_params.align, 'verbosity', 0);
        disp('Estimated alignment with potentially bad matches.')
        disp('If a good alignment was achieved despite a high matching error, you can ignore the matching error by adding the following line to the custom per-section parameters:')
        fprintf('\tparams(%d).xy.max_match_error = inf;\n', sec.num)
    catch
        disp('Section does not have XY alignment and it was not possible to estimate an alignment with the current matches.')
    end
elseif isfield(sec.alignments, 'xy')
    last_alignment = sec.alignments.xy;
end

if ~isempty(last_alignment)
    fprintf('<strong>Prior error</strong>: %f px/match\n', last_alignment.meta.avg_prior_error)
    fprintf('<strong>Post error</strong>: %f px/match\n', last_alignment.meta.avg_post_error)
    disp('Run ''<strong>show_sec(sec, last_alignment)</strong>'' to view the rendered section.')
end
disp('Check xy_params.align for info on parameters used.')

%% Visualize
% Plot rough XY aligned tiles and matches
plot_rough_xy(sec)
plot_matches(last_xy_matches)
append_title(sprintf('\\bfInliers\\rm: %.2fpx/match (n = %d) | \\bfOutliers\\rm: %.2fpx/match (n = %d)', ...
    last_xy_matches.meta.avg_error, last_xy_matches.num_matches, ...
    last_xy_matches.meta.avg_outlier_error, last_xy_matches.meta.num_outliers))

% Plot aligned section
if ~isempty(last_alignment)
    figure
    sec.alignments.last_alignment = last_alignment;
    plot_section(sec, 'last_alignment', 'r0.1')
    sec.alignments = rmfield(sec.alignments, 'last_alignment');
end

