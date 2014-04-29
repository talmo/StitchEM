function empties = areempty(cellarr)
%AREEMPTY Returns a logical array of the size of the cell array indicating whether the cell is empty.

empties = cellfun('isempty', cellarr);

end

