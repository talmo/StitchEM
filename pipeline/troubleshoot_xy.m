fprintf('<strong>\n\n=== Troubleshooting XY: %s (%d/%d)</strong>\n', sec.name, status.section, length(secs))

%% Matching
% Get matches
if isfield(sec, 'xy_matches')
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
    
    disp('Check xy_params.matching for info on parameters used.')
end

% Per tile:
% tile_stats = tile_match_stats(last_xy_matches, sec.grid);
% disp('<strong>Matches per tile:</strong>')
% disp(tile_stats.num_matches)
% disp('<strong>Match error before alignment per tile:</strong>')
% disp(tile_stats.match_error)
% if any(tile_stats.match_error > xy_params.max_match_error)
%     fprintf('<strong>Tiles exceeding max_match_error</strong>: %s\n', vec2str(find(tile_stats.match_error > xy_params.max_match_error)))
% end
   
%% Alignment
disp('== <strong>Alignment</strong>:')
% Check if section has alignment
attempted_alignment = [];
if (exist('alignment_error', 'var') && strcmp(alignment_error.identifier, 'XY:LargeMatchError')) || ...
        ~isfield(sec.alignments, 'xy')
    % Try to align anyway
    try
        attempted_alignment = align_xy(sec, xy_params.align, 'verbosity', 0);
        disp('Estimated alignment with potentially bad matches.')
        fprintf('<strong>Prior error</strong>: %f px/match\n', attempted_alignment.meta.avg_prior_error)
        fprintf('<strong>Post error</strong>: %f px/match\n', attempted_alignment.meta.avg_post_error)
    catch
        disp('Section does not have XY alignment and it was not possible to estimate an alignment with the current matches.')
    end
elseif isfield(sec.alignments, 'xy')
    disp('Alignment error:')
    fprintf('<strong>Prior error</strong>: %f px/match\n', sec.alignments.xy.meta.avg_prior_error)
    fprintf('<strong>Post error</strong>: %f px/match\n', sec.alignments.xy.meta.avg_post_error)
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
if ~isempty(attempted_alignment)
    figure, plot_section(sec, attempted_alignment, 'r0.1')
elseif isfield(sec.alignments, 'xy')
    figure, plot_section(sec, 'xy', 'r0.1')
end

%% Suggestions
fprintf('\n<strong>Suggested next steps:</strong>\n')
disp('- View the features: <strong>plot_xy_features(sec)</strong> or <strong>plot_xy_features(sec, tile)</strong>')
disp('- View rough alignment: <strong>plot_rough_xy(sec)</strong> and <strong>plot_matches(last_xy_matches)</strong>')
disp('- View the rendered section: <strong>show_sec(sec)</strong> or <strong>show_sec(sec, attempted_alignment)</strong>')
fprintf('- Try ignoring the matching error: <strong>params(%d).xy.max_match_error = inf;</strong>\n', sec.num)
disp('- Try using a different parameter preset:')
fprintf('\t<strong>params(%d).xy = xy_presets.grid_align; %% Use grid alignment for rough alignment step</strong>\n', sec.num)
fprintf('\t<strong>params(%d).xy = xy_presets.gmm_filter; %% Use GMM to filter matches</strong>\n', sec.num)