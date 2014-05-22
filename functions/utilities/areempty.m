function empties = areempty(cellarr)
%AREEMPTY Returns a logical array of the size of the cell array indicating each cell is empty.
% Usage:
%   empties = areempty(cellarr)

empties = cellfun('isempty', cellarr);

end

