function idx = incell(x, C)
%INCELL Returns the index of an element in a cell, or 0 if it is not present.
%
% Usage: idx = incell(x, C)
%
% See also: isequal, instr

idx = find(cellfun(@(c) isequal(x, c), C));

if isempty(idx)
    idx = 0;
end

end

