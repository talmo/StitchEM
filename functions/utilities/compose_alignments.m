function alignment = compose_alignments(secA, rel_to_alignments, secB, base_alignment)
%COMPOSE_ALIGNMENTS Returns an alignment that is a composition of relative alignments with a base alignment.
% Usage:
%   alignment = compose_alignments(secA, rel_to_alignments, secB, base_alignment)

if ~iscell(rel_to_alignments)
    rel_to_alignments = {rel_to_alignments};
end

% Get indices for non-missing tiles
idx = find(secA.grid & secB.grid);
idxA = secA.grid(idx);
idxB = secB.grid(idx);

% Initialize relative transforms to identity
rel_tforms = repmat({affine2d()}, size(secB.alignments.(base_alignment).tforms));

% Compose with each alignment
for i = 1:numel(rel_to_alignments)
    rel_alignment = rel_to_alignments{i}; % rel alignment name
    if isfield(secA.alignments, rel_alignment)
        tformsA = secA.alignments.(rel_alignment).rel_tforms;
        rel_tforms(idxB) = compose_tforms(rel_tforms(idxB), tformsA(idxA));
    end
end

% Return alignment structure
alignment.rel_tforms = rel_tforms;
alignment.rel_to = base_alignment;
alignment.rel_to_sec = secA.num;
alignment.rel_to_alignments = rel_to_alignments;
alignment.tforms = compose_tforms(secB.alignments.(base_alignment).tforms, rel_tforms);
alignment.method = 'composed';

end

