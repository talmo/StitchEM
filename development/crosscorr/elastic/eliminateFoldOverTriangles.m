function [xy,uv,tri,badxy,baduv] = eliminateFoldOverTriangles(xy,uv,tri)
            
x = xy(:,1);
y = xy(:,2);

bad_triangles = FindInsideOut(xy,uv,tri);

% find bad_vertices, eliminate bad_vertices
num_bad_triangles = length(bad_triangles);
bad_vertices = zeros(num_bad_triangles,1);
for i = 1:num_bad_triangles
    bad_vertices(i) = FindBadVertex(x,y,tri(bad_triangles(i),:));
end
bad_vertices = unique(bad_vertices);
num_bad_vertices = length(bad_vertices);

% Cache bad vertices that were eliminated
badxy = xy(bad_vertices,:);
baduv = uv(bad_vertices,:);

xy(bad_vertices,:) = []; % eliminate bad ones
uv(bad_vertices,:) = [];
nvert = size(xy,1);

minRequiredPoints = 4;
if (nvert < minRequiredPoints)
    error(message('images:geotrans:deletedPointsNowInsufficientControlPoints', num_bad_vertices, nvert, minRequiredPoints, 'piecewise linear'))
end
x = xy(:,1);
y = xy(:,2);
tri = delaunay(x,y);

% Error if we cannot produce a valid piecewise linear correspondence
% after the second triangulation.
more_bad_triangles = FindInsideOut(xy,uv,tri);
if ~isempty(more_bad_triangles)
    warning(message('images:geotrans:foldoverTrianglesRemain', num_bad_vertices))
end

% Warn to report about triangles and how many points were eliminated
warning(message('images:geotrans:foldoverTriangles', sprintf( '%d ', bad_triangles ), sprintf( '%d ', bad_vertices )))

end

function index = FindInsideOut(xy,uv,tri)

% look for inside-out triangles using line integrals
x = xy(:,1);
y = xy(:,2);
u = uv(:,1);
v = uv(:,2);

p = size(tri,1);

xx = reshape(x(tri),p,3)';
yy = reshape(y(tri),p,3)';
xysum = sum( (xx([2 3 1],:) - xx).* (yy([2 3 1],:) + yy), 1 );

uu = reshape(u(tri),p,3)';
vv = reshape(v(tri),p,3)';
uvsum = sum( (uu([2 3 1],:) - uu).* (vv([2 3 1],:) + vv), 1 );

index = find(xysum.*uvsum<0);

end

function vertex = FindBadVertex(x,y,vertices)

% Get middle vertex of triangle where "middle" means the largest angle,
% which will have the smallest cosine.

vx = x(vertices)';
vy = y(vertices)';
abc = [ vx - vx([3 1 2]); vy - vy([3 1 2]) ];
a = abc(:,1);
b = abc(:,2);
c = abc(:,3);

% find cosine of angle between 2 vectors
vcos(1) = get_cos(-a, b);
vcos(2) = get_cos(-b, c);
vcos(3) = get_cos( a,-c);

[~, index] = min(vcos);
vertex = vertices(index);

end

function vcos = get_cos(a,b)

mag_a = hypot(a(1),a(2));
mag_b = hypot(b(1),b(2));
vcos = dot(a,b) / (mag_a*mag_b);

end