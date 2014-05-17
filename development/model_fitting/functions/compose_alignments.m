function alignment = compose_alignments(secA, rel_to_alignments, secB, base_alignment)
%COMPOSE_ALIGNMENTS Returns an alignment that is a composition of relative alignments with a base alignment.
% Usage:
%   alignment = compose_alignments(secA, rel_to_alignments, secB, base_alignment)

%rel_to_alignments = {'prev_z', 'z'}; % which alignments on previous section
%base_alignment = 'xy'; % which alignment on this section

if ~iscell(rel_to_alignments)
    rel_to_alignments = {rel_to_alignments};
end

rel_tforms = repmat({affine2d()}, size(secB.alignments.(base_alignment).tforms));
for i = 1:numel(rel_to_alignments)
    rel_alignment = rel_to_alignments{i};
    if isfield(secA.alignments, rel_alignment)
        rel_tforms = compose_tforms(rel_tforms, secA.alignments.(rel_alignment).rel_tforms);
    end
end
alignment.rel_tforms = rel_tforms;
alignment.rel_to = base_alignment;
alignment.rel_to_sec = secA.num;
alignment.rel_to_alignments = rel_to_alignments;
alignment.tforms = compose_tforms(secB.alignments.(base_alignment).tforms, rel_tforms);
alignment.method = 'composed';

end

