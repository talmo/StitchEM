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
    %plot_displacements(secB.z_matches)
end

%% Alignment
disp('== <strong>Alignment</strong>:')
% Check if section has alignment
attempted_alignment = [];
if (exist('alignment_error', 'var') && strcmp(alignment_error.identifier, 'Z:LargeMatchError')) || ...
        ~isfield(sec.alignments, 'z')
    % Try to align anyway
    try
        switch z_params.alignment_method
            case 'lsq'
                % Least Squares
                attempted_alignment = align_z_pair_lsq(secB, last_z_matches, last_z_matches.alignmentB);

            case 'cpd'
                % Coherent Point Drift
                attempted_alignment = align_z_pair_cpd(secB, last_z_matches, last_z_matches.alignmentB, 0);
        end
        
        disp('Estimated alignment with potentially bad matches.')
        fprintf('<strong>Prior error</strong>: %f px/match\n', attempted_alignment.meta.avg_prior_error)
        fprintf('<strong>Post error</strong>: %f px/match\n', attempted_alignment.meta.avg_post_error)
        
        plot_section_pair(secA, secB, attempted_alignment)
    catch
        disp('Section does not have Z alignment and it was not possible to estimate an alignment with the current matches.')
    end
    
elseif isfield(sec.alignments, 'z')
    disp('Alignment error:')
    fprintf('<strong>Prior error</strong>: %f px/match\n', sec.alignments.xy.meta.avg_prior_error)
    fprintf('<strong>Post error</strong>: %f px/match\n', sec.alignments.xy.meta.avg_post_error)
end

disp('Check z_params.align for info on parameters used.')

%% Suggestions
fprintf('\n<strong>Suggested next steps:</strong>\n')
disp('- View the features: <strong>plot_z_features(secB)</strong> or <strong>plot_z_features(secB, tile)</strong>')
disp('- View the matches: <strong>plot_z_matches(secA, secB)</strong>')
disp('- View the displacements: <strong>plot_displacements(secB.z_matches)</strong>')
disp('- View the aligned sections: <strong>plot_section_pair(secA, secB)</strong>')
disp('- View the rendered section: <strong>show_sec(secB)</strong>')
fprintf('- Try ignoring the matching error: <strong>params(%d).z.max_match_error = inf;</strong>\n', secB.num)
disp('- Try using a different parameter preset:')
fprintf('\t<strong>params(%d).z = z_presets.low_res; %% Detect features at 0.075x resolution</strong>\n', secB.num)
fprintf('\t<strong>params(%d).z = z_presets.manual_matching; %% Specify matches manually</strong>\n', secB.num)
fprintf('\t<strong>params(%d).z = z_presets.rel_to_2previous; %% Align to two sections below</strong>\n', secB.num)
fprintf('\t<strong>params(%d).z = z_presets.large_trans; %% Ignore matching error and cluster by smallest variance</strong>\n', secB.num)
fprintf('\n<strong>Original error</strong>:\n')
rethrow(alignment_error)
