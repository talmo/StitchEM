%% Configuration
%s = 2;
%secA = secs{s - 1};
%secB = secs{s};
matches = secB.corr_matches;
ptsA = matches.A.global_points;
ptsB = matches.B.global_points;

%% Visualize
figure
plot_section(secA, 'blockcorr', 'r0.1')
plot_section(secB, 'z', 'g0.1')
plot_matches(matches)

%% Control (CPD affine)
% Solve
tform = cpd_solve(ptsA, ptsB, 'method', 'affine', 'viz', false);

% Displacements
ptsB2 = tform.transformPointsForward(ptsB);
D1 = ptsB - ptsA;
D2 = ptsB2 - ptsA;

% Errors
prior_error = rownorm2(D1);
post_error = rownorm2(D2);

disp('<strong>Control</strong>: CPD (affine)')
fprintf('<strong>Prior error</strong>: %f px/match\n', prior_error)
fprintf('<strong>Post error</strong>: %f px/match\n', post_error)

%% Control (LSQ)
% Solve
tform = lsq_solve(ptsA, ptsB);

% Displacements
ptsB2 = tform.transformPointsForward(ptsB);
D1 = ptsB - ptsA;
D2 = ptsB2 - ptsA;

% Errors
prior_error = rownorm2(D1);
post_error = rownorm2(D2);

disp('<strong>Control</strong>: LSQ')
fprintf('<strong>Prior error</strong>: %f px/match\n', prior_error)
fprintf('<strong>Post error</strong>: %f px/match\n', post_error)

%% Align with CPD (non-linear)
% Solve
tform = cpd_solve(ptsA, ptsB, 'method', 'nonrigid', 'viz', false);

% Displacements
ptsA2 = tform.transformPointsInverse(ptsA);
D1 = ptsB - ptsA;
D2 = ptsB - ptsA2;

% Errors
prior_error = rownorm2(D1);
post_error = rownorm2(D2);

disp('<strong>Test</strong>: CPD (nonrigid)')
fprintf('<strong>Prior error</strong>: %f px/match\n', prior_error)
fprintf('<strong>Post error</strong>: %f px/match\n', post_error)

%% Align with CPD (non-linear, low-rank)
% Solve
tform = cpd_solve(ptsA, ptsB, 'method', 'nonrigid_lowrank', 'viz', false);

% Displacements
ptsA2 = tform.transformPointsInverse(ptsA);
D1 = ptsB - ptsA;
D2 = ptsB - ptsA2;

% Errors
prior_error = rownorm2(D1);
post_error = rownorm2(D2);

disp('<strong>Test</strong>: CPD (nonrigid_lowrank)')
fprintf('<strong>Prior error</strong>: %f px/match\n', prior_error)
fprintf('<strong>Post error</strong>: %f px/match\n', post_error)


%% Visualize displacements
figure, plot_displacements(D1)
figure, plot_displacements(D2)

%% Visualize tiles
% Tiles
tilesA = sec_bb(secA, 'blockcorr');
tilesB = sec_bb(secB, 'z');
tilesA2 = cellfun(@(bb) tform.transformPointsInverse(bb), tilesA, 'UniformOutput', false);

% Plot
figure, draw_polys(tilesA, 'g0.1'), title('Alignment: z')
figure, draw_polys(tilesA2, 'b0.1'), title('Alignment: CPD (non-rigid)')

%% Memory limits (full mode)
n = logspace(1,6,6)'; % number of points (goal = ~7e7)
cpd_method = 'nonrigid';

% Find alignment transform
clear tform new_pts
tform = cpd_solve(ptsA, ptsB, 'method', cpd_method);

% Run test
runtimes = zeros(size(n));
for i = 1:length(n)
    test_pts = ones(n(i), 2);
    tic;
    new_pts = tform.transformPointsInverse(test_pts);
    runtimes(i) = toc;
    fprintf('n = %d: %fs\n', n(i), runtimes(i))
    clear new_pts
end
results = table(n, runtimes);

%% Memory limits (block mode)
n = logspace(5,7,3)'; % number of points (goal = ~7e7)
%b = logspace(3,5,3)';
b = 1e5;
cpd_method = 'nonrigid';

% Find alignment transform
clear tform new_pts
tform = cpd_solve(ptsA, ptsB, 'method', cpd_method);
tform.mode = 'parblock';

% Run test
runtimes = zeros(length(n) * length(b), 1);
for i = 1:length(n)
    test_pts = ones(n(i), 2);
    for j = 1:length(b)
        tform.block_sz = b(j);
        tic;
        new_pts = tform.transformPointsInverse(test_pts);
        runtime = toc;
        runtimes(find(runtimes == 0, 1)) = runtime;
        fprintf('n = %d | b = %d: %fs\n', n(i), b(j), runtime)
        clear new_pts
    end
end
%% Full vs block
n = 1e6; % number of points (goal = ~7e7)
b = 1e4; % block size
cpd_method = 'nonrigid';

% Find alignment transform
clear tform tform_block full block
tform = cpd_solve(ptsA, ptsB, 'method', cpd_method);
tform_block = tform;
tform_block.mode = 'block';
tform_block.block_sz = b;

% Set up timing test
test_pts = ones(n, 2);
full = @() tform.transformPointsInverse(test_pts);
block = @() tform_block.transformPointsInverse(test_pts);

% Test
fprintf('<strong>Transform performance</strong> (n = %d points):\n', n)
tic; block_pts = block(); block_time = toc;
fprintf('<strong>Block</strong> (sz = %d): %fs\n', b, block_time)
tic; full_pts = full(); full_time = toc;
fprintf('<strong>Full</strong>: %fs\n', full_time)
assert(all(all(full_pts == block_pts)))


%% Tile image
t = 1;
tform = cpd_solve(ptsA, ptsB, 'method', 'nonrigid');
tform.mode = 'parblock';

% Load tile
tileA = imload_tile(secB, t); tileA_R = imref2d(size(tileA));

% Apply base transform (linear)
tic; [tileB, tileB_R] = imwarp(tileA, secB.alignments.z.tforms{t}); toc
%Elapsed time is 3.019198 seconds.

% Apply CPD transform (non-linear)
tic; [tileC, tileC_R] = imwarp(tileB, tileB_R, tform); toc
%Elapsed time is 299.611955 seconds.

%% Section image
tform = cpd_solve(ptsA, ptsB, 'method', 'nonrigid');
tform.mode = 'parblock';

% Render sections with base linear alignments
[A, RA] = render_section(secA, 'blockcorr', 'scale', 0.05);
[B, RB] = render_section(secB, 'z', 'scale', 0.05);

% Apply non-linear alignment to secB
tic; [B2, RB2] = imwarp(B, RB, tform); toc

%% Visualize
figure, imshowpair(A, RA, B, RB, 'diff'), ax2int(), title('A and B')
figure, imshowpair(A, RA, B2, RB2, 'diff'), ax2int(), title('A and B2')
figure, imshowpair(B, RB, B2, RB2, 'diff'), ax2int(), title('B and B2')