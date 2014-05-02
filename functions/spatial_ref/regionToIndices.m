function idx = regionToIndices(region, sz)
%REGIONTOINDICES Converts a region to image indices.

% Find the rows and cols of the bounds
subs = regionToSubscripts(region, sz);

% Make a grid of rows and column coordinates
[cols, rows] = meshgrid(subs(1, 2):subs(2, 2), subs(1, 1):subs(2, 1));

% Convert to indices
idx = sub2ind(sz, rows, cols);

end

