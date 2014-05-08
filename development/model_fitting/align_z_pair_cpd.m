function alignmentB = align_z_pair_cpd(secB, z_matches)
%ALIGN_Z_PAIR_CPD Produces a Z alignment using Coherent Point Drift.
% Usage:
%   alignmentB = align_z_pair_cpd(secA, secB, z_matches)

total_time = tic;

% Merge matches into a single table
matches = merge_match_sets(z_matches);

% CPD options
opt.method = 'affine'; % 'rigid', 'affine', 'nonrigid'
opt.viz = 0;
opt.verbosity = 0;

% Solve using CPD
cpd_tform = cpd_register(matches.A.global_points, matches.B.global_points, opt);
tform = affine2d([[cpd_tform.s * cpd_tform.R'; cpd_tform.t'] [0 0 1]']);

% All the transforms are adjusted by the same section transformation
rel_to = 'xy';
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

fprintf('Error: %f -> %fpx / match (%d matches) [%.2fs]\n', avg_prior_error, avg_post_error, z_matches.num_matches, toc(total_time))

end

