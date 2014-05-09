function I = intersect_polys(P, Q)
%INTERSECT_POLYS Finds the intersection between two convex polygons, P and Q.
% This is the most naive intersection algorithm for a pair of convex
% polygons.

I = [];

% Do a fast first-order approximation: if their bounding boxes do not
% overlap, then there will be no intersection
if ~bb_hittest(P, Q)
    return
end

% Make sure P and Q are convex hulls
P = P(convhull(double(P), 'simplify', true), :);
Q = Q(convhull(double(Q), 'simplify', true), :);

% Find intersections between every pair of edges in P and Q
for i = 1:size(P, 1) - 1
    Pi = [P(i, :); P(i + 1, :)]; % edge i in P
    for j = 1:size(Q, 1) - 1
        Qj = [Q(j, :); Q(j + 1, :)]; % edge j in Q
        
        % Find intersections between these edges
        I = [I; intersect_line_segs(Pi, Qj)];
    end
end

% Find intersecting vertices
PinQ = inpolygon(P(:, 1), P(:, 2), Q(:, 1), Q(:, 2));
QinP = inpolygon(Q(:, 1), Q(:, 2), P(:, 1), P(:, 2));
I = [I; P(PinQ, :); Q(QinP, :)];

% Check if we have enough points to form an intersection
if size(I, 1) < 3
    I = [];
    return
end

% Format as convex hull of all intersecting points
I = I(convhull(double(I), 'simplify', true), :);
end

