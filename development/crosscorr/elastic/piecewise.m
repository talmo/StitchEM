%% Configuration
%s = 2;
%secA = secs{s - 1};
%secB = secs{s};
matches = secB.corr_matches;

%% Visualize
figure
plot_section(secA, 'blockcorr', 'r0.1')
plot_section(secB, 'z', 'g0.1')
plot_matches(matches)

%% Triangulation
% Syntax from: images.geotrans.PiecewiseLinearTransformation2D
xy = matches.A.global_points; % fixed
uv = matches.B.global_points; % moving

% Vectors
x = xy(:,1); y = xy(:,2);
u = uv(:,1); v = uv(:,2);

% Triangulate
tri = delaunay(x, y);

%% Visualize
figure
triplot(tri, x, y), hold on
plot_matches(matches)
axis ij equal
ax2int, grid on

%% Filter triangles
% Eliminate foldover triangles
[good_xy, good_uv, good_tri, bad_xy, bad_uv] = eliminateFoldOverTriangles(xy, uv, tri);

%% Visualize
figure
triplot(good_tri, good_xy(:,1), good_xy(:,2)), hold on
plot(good_xy(:,1), good_xy(:,2), 'g.')
plot(bad_xy(:,1), bad_xy(:,2), 'r*')
axis ij equal
ax2int, grid on

%% Alignment
tform = fitgeotrans(matches.B.global_points, matches.A.global_points, 'pwl');
D1 = matches.B.global_points - matches.A.global_points;
D2 = matches.B.global_points - tform.transformPointsInverse(matches.A.global_points);

prior_error = rownorm2(D1);
post_error = rownorm2(D2);

fprintf('<strong>Prior error</strong>: %f px/match\n', prior_error)
fprintf('<strong>Post error</strong>: %f px/match\n', post_error)

%% Apply to image
t = 1;
% Load tile
tileA = imload_tile(secB, t); tileA_R = imref2d(size(tileA));

% Apply base transform (linear)
tic; [tileB, tileB_R] = imwarp(tileA, secB.alignments.z.tforms{t}); toc

% Apply PWL transform (non-linear)
tic; [tileC, tileC_R] = imwarp(tileB, tileB_R, tform); toc

%% Visualize
figure, imshow(tileB, tileB_R)
figure, imshow(tileC, tileC_R)