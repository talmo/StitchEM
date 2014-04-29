function w = in_poly(points, vertices)
%IN_POLY Calculates the winding number of the points.

n = size(vertices,1);
m = size(points,1);

q = zeros(2, n + 1);
q(:, 1:n) = vertices';
q(:, n + 1) = q(:, 1);

i = 1:n;
j = 2:n + 1;

ym = repmat(2, m, 1);
yn = repmat(2, 1, n);

w = abs(sum((2 * ((repmat(q(1, i) .* q(2, j) - q(2, i) .* q(1, j), m, 1) + points(:, 1) * (q(2,i) - q(2, j)) + points(:, 2) * (q(1, j) - q(1, i))) > 0) - 1) .* abs((q(ym, j) > points(:, yn)) - (q(ym, i) > points(:, yn))), 2) / 2);
end