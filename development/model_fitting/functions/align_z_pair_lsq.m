function alignmentB = align_z_pair_lsq(secB, z_matches)
%ALIGN_Z_PAIR_LSQ Produces a Z alignment using least squares.
% Usage:
%   alignmentB = align_z_pair_lsq(secB, z_matches)

base_alignment = 'rough_z';

total_time = tic;
fprintf('== Aligning section %d to %d (LSQ)\n', z_matches.secB, z_matches.secA)

% Merge matches into a single table
matches = merge_match_sets(z_matches);

% Solve using least squares
% Ax = B -> x = A \ B
T = [matches.B.global_points ones(z_matches.num_matches, 1)] \ [matches.A.global_points ones(z_matches.num_matches, 1)];
tform = affine2d([T(:, 1:2) [0 0 1]']);

% All the transforms are adjusted by the same section transformation
rel_to = base_alignment;
rel_tforms = repmat({tform}, secB.num_tiles, 1);
tforms = cellfun(@(t1, t2) compose_tforms(t1, t2), secB.alignments.(rel_to).tforms, rel_tforms, 'UniformOutput', false);

% Calculate error
avg_prior_error = rownorm2(bsxadd(matches.B.global_points, -matches.A.global_points));
avg_post_error = rownorm2(bsxadd(tform.transformPointsForward(matches.B.global_points), -matches.A.global_points));

% Save to structure
alignmentB.tforms = tforms;
alignmentB.rel_tforms = rel_tforms;
alignmentB.rel_to = rel_to;
alignmentB.meta.avg_prior_error = avg_prior_error;
alignmentB.meta.avg_post_error = avg_post_error;
alignmentB.meta.method = mfilename;

fprintf('Error: %f -> <strong>%fpx / match</strong> [%.2fs]\n', avg_prior_error, avg_post_error, toc(total_time))
end

