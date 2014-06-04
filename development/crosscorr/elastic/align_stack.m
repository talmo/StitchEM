%% Parameters
params.cpd.method = 'nonrigid'; % 'rigid', 'affine', 'nonrigid', 'nonrigid_lowrank'
params.cpd.tform_method = 'parblock';

%% Matching
% assumes it's already done

%% Alignment
for s = 1:length(secs)
    if s == 1
        secs{s}.alignments.elastic = fixed_alignment(secs{s}, 'z');
        continue
    end
    align_timer = tic;
    
    secA = secs{s - 1};
    secB = secs{s};
    
    % Align
    ptsA = secB.corr_matches.A.global_points;
    ptsB = secB.corr_matches.B.global_points;
    tform = cpd_solve(ptsA, ptsB, params.cpd);

    % Calculate error
    prior_error = rownorm2(ptsB - ptsA);
    post_error = rownorm2(tform.transformPointsInverse(ptsA) - ptsB);
    
    % Alignment structure
    alignment.rel_tforms = repmat({tform}, secB.num_tiles, 1);
    alignment.rel_to = 'z';
    alignment.meta.avg_prior_error = prior_error;
    alignment.meta.avg_post_error = post_error;
    alignment.meta.method = 'blockcorr';
    secB.alignments.elastic = alignment;
    
    % Save
    secs{s} = secB;
    
    fprintf('Aligned <strong>%s</strong>. Error: %f -> <strong>%f px/match</strong> [%.2fs]\n', ...
        secB.name, prior_error, post_error, toc(align_timer))
end

%% Stack ref
stack_ref_time = tic;
% Get stack from base alignment
[~, sec_Rs] = stack_ref(secs, 'z');
fprintf('Merged stack refs using ''z'' alignment. [%.2fs]\n', toc(stack_ref_time))

% Transform with elastic alignment
elastic_ref_time = tic;
parfor s = 1:length(secs)
    tform = secs{s}.alignments.elastic.rel_tforms{1};
    sec_Rs{s} = cellfun(@(R) tform_spatial_ref(R, tform), sec_Rs{s}, 'UniformOutput', false);
end
final_stack_R = merge_spatial_refs(vertcat(sec_Rs{:}));
fprintf('Merged stack refs using ''elastic'' alignment. [%.2fs]\n', toc(elastic_ref_time))

%% Render (section)
render_scale = 0.05;
folder_name = sprintf('%s_Secs%d-%d_%s(%s)', secs{1}.wafer, secs{1}.num, secs{end}.num, 'elastic', num2str(render_scale));
folder_path = create_folder(folder_name);

% Scale refs
scaled_stack_R = scale_ref(final_stack_R, 0.05);

for s = 1:length(secs)
    sec = secs{s};
    elastic_alignment = 'elastic';
    base_alignment = sec.alignments.(elastic_alignment).rel_to;
    tform = sec.alignments.(elastic_alignment).rel_tforms{1};
    
    % Render section with base linear alignment
    [A, RA] = render_section(sec, base_alignment, 'scale', render_scale, 'stack_R', scaled_stack_R);

    % Apply non-linear alignment
    nonrigid_time = tic;
    [B, RB] = imwarp(A, RA, tform);
    fprintf('Rendered <strong>%s</strong> with non-rigid alignment. [%.2fs]\n', sec.name, toc(nonrigid_time))
    
    % Save
    output_path = fullfile(folder_path, [sec.name '.tif']);
    imwrite(output_path, 'B')
end