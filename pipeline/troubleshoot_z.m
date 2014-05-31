fprintf('<strong>\n\n=== Troubleshooting Z: %s (%d/%d)</strong>\n', secB.name, status.section, length(secs))

%% Matching
if isfield(secB, 'z_matches')
    last_z_matches = secB.z_matches;

    if ~isfield(last_z_matches, 'outliers')
        % Redetect matches with same parameters but keep outliers
        last_z_matches = match_z(secA, secB, 'base_z', 'z', z_params.matching, 'keep_outliers', true, 'verbosity', 0);
    end

    disp('== <strong>Matching</strong>:')
    fprintf('<strong>NNR</strong>: %f px/match (n = %d)\n', last_z_matches.meta.avg_nnr_error, last_z_matches.meta.num_nnr_matches)
    fprintf('<strong>Inliers</strong>: %f px/match (n = %d)\n', last_z_matches.meta.avg_error, last_z_matches.num_matches)
    fprintf('<strong>Outliers</strong>: %f px/match (n = %d)\n', last_z_matches.meta.avg_outlier_error, last_z_matches.meta.num_outliers)
    fprintf('<strong>Filtering method used</strong>: %s\n', last_z_matches.meta.filtering.method)

    % Show displacements
    plot_displacements(secB.z_matches)
end

%% Suggestions
fprintf('\n<strong>Suggested next steps:</strong>\n')
disp('- View the features: <strong>plot_z_features(secB)</strong> or <strong>plot_z_features(secB, tile)</strong>')
disp('- View the matches: <strong>plot_z_matches(secA, secB)</strong>')
disp('- View the aligned sections: <strong>plot_section(secA, ''z'', ''r0.1''), plot_section(secB, ''z'', ''g0.1'')</strong>')
disp('- View the rendered section: <strong>show_sec(secB)</strong>')
fprintf('- Try ignoring the matching error: <strong>params(%d).z.max_match_error = inf;</strong>\n', secB.num)
disp('- Try using a different parameter preset:')
fprintf('\t<strong>params(%d).z = z_presets.low_res; %% Detect features at 0.075x resolution</strong>\n', secB.num)
fprintf('\t<strong>params(%d).z = z_presets.manual_matching; %% Specify matches manually</strong>\n', secB.num)
fprintf('\t<strong>params(%d).z = z_presets.rel_to_2previous; %% Align to two sections below</strong>\n', secB.num)
fprintf('\t<strong>params(%d).z = z_presets.large_trans; %% Ignore matching error and cluster by smallest variance</strong>\n', secB.num)
fprintf('\n<strong>Original error</strong>:\n')
rethrow(alignment_error)
