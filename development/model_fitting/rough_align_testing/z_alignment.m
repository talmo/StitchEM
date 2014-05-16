% Keep first section fixed relative to the XY alignment
base_alignment = 'xy';
alignment.tforms = secs{1}.alignments.(base_alignment).tforms;
alignment.rel_tforms = repmat({affine2d()}, size(alignment.tforms));
alignment.rel_to = base_alignment;
secs{1}.alignments.z = alignment;

%%
s = 2;
secA = secs{s - 1};
secB = secs{s};

% [xy_rel] Compose XY with previous Z
% Align overviews
% [rough_z] Compose XY+previous Z with relative overview tform
% Detect features in intersect of secA.z <-> secB.rough_z
% Match features with NNR
% Filter with GMM
% [z] Align matches on secB to secA