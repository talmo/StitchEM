%% Configuration
% Assumes secs already has corr_matches field and blockcorr alignment
% s = 3;
% secA = secs{s - 1};
% secB = secs{s};
% matches = secB.corr_matches;
ptsA = matches.A.global_points;
ptsB = matches.B.global_points;

%% Just points on one tile
t = 1;
idx = matches.A.tile == t & matches.B.tile == t;
ptsA = matches.A.global_points(idx, :);
ptsB = matches.B.global_points(idx, :);

%% Visualize
figure
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'z', 'g0.1'), hold on
plot_matches(ptsA, ptsB)

figure
plot_displacements(ptsA, ptsB)

%% Align
% Fit transform
%tform = fitgeotrans(ptsB,ptsA,'polynomial',3);
tform = fitgeotrans(ptsB, ptsA, 'pwl'); % moving, fixed
%tform = fitgeotrans(ptsB, ptsA, 'lwm', 6);

% Calculate errors
prior_error = rownorm2(ptsB - ptsA);
post_error = rownorm2(ptsB - tform.transformPointsInverse(ptsA));
fprintf('Prior error = %f px / match\n', prior_error)
fprintf('Post error = %f px / match\n', post_error)

%% CPD align
tform = cpd_solve(ptsA, ptsB, 'method', 'affine', 'verbosity', 0, 'viz', 1);
%ptsB_cpd = cpd_transform(ptsB, Transform);
ptsB_cpd = tform.transformPointsForward(ptsB);

% Calculate errors
prior_error = rownorm2(ptsB - ptsA);
post_error = rownorm2(ptsB_cpd - ptsA);
fprintf('Prior error = %f px / match\n', prior_error)
fprintf('Post error = %f px / match\n', post_error)

%% Load and transform tiles to z alignment
tileA = imload_tile(secA, t);
[tileA, RA] = imwarp(tileA, secA.alignments.z.tforms{t});
tileB = imload_tile(secB, t);
[tileB, RB] = imwarp(tileB, secB.alignments.z.tforms{t});
disp('Loaded tiles.')

%% Test render
% Output ref
R_out = tform_spatial_ref(RB, tform);

% Create grid to interpolate to
M = R_out.ImageSize(1); N = R_out.ImageSize(2);
[x, y] = meshgrid(1:N, 1:M);
grid = [x(:) y(:)];

% Transform the grid according to the estimated transformation
T = tform.transformPointsForward(grid);

% Interpolate the image
Tx = reshape(T(:,1), [M N]);
Ty = reshape(T(:,2), [M N]);
result = interp2(tileB, Tx, Ty);

disp('Done transforming tile.')

%% Transform first tile
tA = 1;
tileA = imload_tile(secA, tA);
[tileA, RA] = imwarp(tileA, secA.alignments.blockcorr.tforms{tA});

tB = 1;
tileB = imload_tile(secB, tB);
[tileB, RB] = imwarp(tileB, secB.alignments.z.tforms{tB});
[tileB2, RB2] = imwarp(tileB, RB, tform);

%% Visualize
%imshowpair(