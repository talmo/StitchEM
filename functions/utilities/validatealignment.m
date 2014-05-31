function [valid_alignment, alignment_name] = validatealignment(alignment, sec)
%VALIDATEALIGNMENT Checks if the alignment is valid and returns a valid alignment structure.
% Usage:
%   valid_alignment = validatealignment(alignment)
%   valid_alignment = validatealignment(alignment, sec)
%   [valid_alignment, alignment_name] = validatealignment(alignment, sec)

switch class(alignment)
    case 'struct'
        valid_alignment = alignment;
    case 'char'
        assert(nargin == 2, 'Alignment is a string, but a section was not provided.')
        alignment = validatestring(alignment, fieldnames(sec.alignments));
        valid_alignment = sec.alignments.(alignment);
    case 'cell'
        assert(all(cellfun(@istform, alignment)), 'Cell array must contain only geometric transforms')
        valid_alignment = struct();
        valid_alignment.tforms = alignment;
end
assert(isfield(valid_alignment, 'tforms'), 'Alignment structure must have a ''tforms'' field.')

if nargin > 1
    assert(numel(valid_alignment.tforms) == sec.num_tiles, 'Number of transforms in alignment must match the number of tiles in the section.')
end

alignment_name = sprintf('%d transforms', numel(valid_alignment.tforms));
if isfield(valid_alignment, 'meta') && isfield(valid_alignment.meta, 'method')
    alignment_name = valid_alignment.meta.method;
end
if isfield(valid_alignment, 'rel_to')
    alignment_name = sprintf('Relative to ''%s''', valid_alignment.rel_to);
end
if ischar(alignment)
    alignment_name = alignment;
end

end

