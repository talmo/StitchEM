function alignment = rough_align_z(secA, secB, varargin)
%ROUGH_ALIGN_Z Rough aligns secB to secA based on their overviews.

% A: rough_xy -> xy -> (rough) -> z
% B: rough_xy -> xy
%
% intermediate = secB.alignments.rough_xy.meta.intermediate_tforms;
% initialToOverview = intermediate.prescale -> intermediate.registration
% initialToOverview -> overview.alignment -> inv(initialToOverview)
% inv(base) -> initialToOverview -> overview.alignment -> inv(initialToOverview) -> base


base_tforms = secB.alignments.xy.tforms;

% Get the intermediate tforms in the rough XY alignment
intermediates = secB.alignments.rough_xy.meta.intermediate_tforms;

% Transforms to go from initial to the overview
initial2overview = cellfun(@(intermediate) compose_tforms(intermediate.prescale, intermediate.registration), intermediates, 'UniformOutput', false);

overview_tform = secB.overview.alignment.tform;

% base -> initial -> overview -> (apply overview alignment) -> initial -> base -> z_prev
rel_tforms = cellfun(@(base, i2o, z_rel) compose_tforms(base.invert, i2o, overview_tform, i2o.invert, base, z_rel), base_tforms, initial2overview, secA.alignments.z.rel_tforms, 'UniformOutput', false);
tforms = compose_tforms(base_tforms, rel_tforms);

alignment.rel_tforms = rel_tforms;
alignment.tforms = tforms;
end