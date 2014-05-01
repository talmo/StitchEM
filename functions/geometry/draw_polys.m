function draw_polys(polygons)
%DRAW_POLYS Draw an array of polygons.
%   This is a simple wrapper for draw_poly.

for i = 1:numel(polygons)
    draw_poly(polygons{i});
end

end

