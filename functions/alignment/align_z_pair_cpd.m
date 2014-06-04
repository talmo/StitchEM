function alignmentB = align_z_pair_cpd(secB, z_matches, base_alignment, verbosity)
%ALIGN_Z_PAIR_CPD Produces a Z alignment using Coherent Point Drift.
% Usage:
%   alignmentB = align_z_pair_cpd(secB)
%   alignmentB = align_z_pair_cpd(secB, z_matches)
%   alignmentB = align_z_pair_cpd(secB, z_matches, base_alignment)
%   alignmentB = align_z_pair_cpd(secB, z_matches, base_alignment, verbosity)

if nargin < 2
    z_matches = secB.z_matches;
end
if nargin < 3
    base_alignment = z_matches.alignmentB;
end
if nargin < 4
    verbosity = 1;
end

total_time = tic;
if verbosity > 0; fprintf('== Aligning %s in Z (CPD)\n', secB.name); end

% CPD options
opt.method = 'affine'; % 'rigid', 'affine', 'nonrigid'
opt.viz = 0;
opt.verbosity = verbosity - 1;

% Solve alignment transform
tform = cpd_solve(z_matches.A.global_points, z_matches.B.global_points, opt);

% All the transforms are adjusted by the same section transformation
rel_to = base_alignment;
rel_tforms = repmat({tform}, secB.num_tiles, 1);
tforms = cellfun(@(t1, t2) compose_tforms(t1, t2), secB.alignments.(rel_to).tforms, rel_tforms, 'UniformOutput', false);

% Calculate error
avg_prior_error = rownorm2(z_matches.B.global_points - z_matches.A.global_points);
avg_post_error = rownorm2(tform.transformPointsForward(z_matches.B.global_points) - z_matches.A.global_points);

% Save to structure
alignmentB.tforms = tforms;
alignmentB.rel_tforms = rel_tforms;
alignmentB.rel_to = rel_to;
alignmentB.meta.avg_prior_error = avg_prior_error;
alignmentB.meta.avg_post_error = avg_post_error;
alignmentB.meta.method = mfilename;
alignmentB.meta.tform_type = opt.method;

if verbosity > 0; fprintf('Error: %f -> <strong>%fpx / match</strong> [%.2fs]\n', avg_prior_error, avg_post_error, toc(total_time)); end
end

