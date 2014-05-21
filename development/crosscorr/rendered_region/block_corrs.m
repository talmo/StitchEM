%% Configuration

A = imread('S2-W003_secs1-169_z_aligned[7000,15000]/0.45x,lsq/S2-W003_Sec1_Montage.tif');
R_A = imref2d(size(A));
B = imread('S2-W003_secs1-169_z_aligned[7000,15000]/0.45x,lsq/S2-W003_Sec2_Montage.tif');
R_B = imref2d(size(B));

% Sanity checks (artificial distortions):
%distortion = make_tform('translate', [50, 50]);
%distortion = make_tform('rotate', 2.5);
%distortion = make_tform('scale', 0.95);
%[B, R_B] = imwarp(A, R_A, distortion, 'FillValues', mean(A(:)));

%B = padarray(A, [50, 100], mean(A(:)), 'pre');
%R_B = imref2d(size(B));

grid_sz = [200, 200];
block_sz = [150, 150];

%% Correlation
A_loc = [R_A.YWorldLimits(1), R_A.XWorldLimits(1)];
B_loc = [R_B.YWorldLimits(1), R_B.XWorldLimits(1)];
base_offset = A_loc - B_loc;
[rows, cols] = meshgrid(1:grid_sz(1):size(B, 1), 1:grid_sz(2):size(B, 2));
locations = [rows(:), cols(:)];
offsets = NaN(size(locations));
corrs = NaN(length(locations), 1);

fprintf('Finding cross-correlation in %d regions...\n', length(locations)), tic
parfor i = 1:length(locations)
    loc = locations(i, :);
    block = B(loc(1):min(loc(1)+block_sz(1)-1, size(B, 1)), ...
              loc(2):min(loc(2)+block_sz(2)-1, size(B, 2)));
    if std(double(block(:))) == 0
        continue
    end
    C = normxcorr2(block, A);
    %[peak_corr, peak_idx] = max(C(:));
    %[peakI, peakJ] = ind2sub(size(C), peak_idx);
    [peakJ, peakI, peak_corr] = findpeak(C, true);
    offset = [peakI, peakJ] - size(block);
    corrs(i) = peak_corr;
    offsets(i, :) = base_offset + offset - loc + [1, 1];
end
fprintf('Done. [%.2fs]\n', toc)

not_nan = ~isnan(corrs);
mean_corr = mean(corrs(not_nan));
mean_offset = mean(offsets(not_nan, :));

fprintf('mean corr = %f\n', mean_corr)
fprintf('mean offset = [%f, %f]\n', mean_offset)

% Convert to XY coordinates
pointsA = fliplr(locations(not_nan, :));
pointsB = fliplr(locations(not_nan, :) - offsets(not_nan, :));

%% Visualize
figure
quiver(pointsA(:,1), pointsA(:,2), pointsB(:,1)-pointsA(:,1), pointsB(:,2)-pointsA(:,2))
grid on
axis ij equal

%% Matches
figure
imshowpair(A, R_A, B, R_B)
plot_matches(pointsA, pointsB)

%% Align B -> A (LSQ)
ptsA = pointsA;
ptsB = pointsB;
fprintf('Prior error: %f px/match\n', rownorm2(ptsB - ptsA))

[ptsA, ptsB] = gmm_filter(ptsA, ptsB);
fprintf('After filtering: %f px/match\n', rownorm2(ptsB - ptsA))

T = [ptsB ones(length(ptsB), 1)] \ [ptsA ones(length(ptsA), 1)];
tform = affine2d([T(:, 1:2) [0 0 1]']);

ptsB_reg = tform.transformPointsForward(ptsB);
fprintf('Post error: %f px/match\n', rownorm2(ptsB_reg - ptsA))

%% Align B -> A (CPD)
ptsA = pointsA;
ptsB = pointsB;
fprintf('Prior error: %f px/match\n', rownorm2(ptsB - ptsA))

[ptsA, ptsB] = gmm_filter(ptsA, ptsB);
fprintf('After filtering: %f px/match\n', rownorm2(ptsB - ptsA))

tform = cpd_solve(ptsA, ptsB, 'affine', true);

ptsB_reg = tform.transformPointsForward(ptsB);
fprintf('Post error: %f px/match\n', rownorm2(ptsB_reg - ptsA))

%% Visualize
figure
quiver(ptsA(:,1), ptsA(:,2), ptsB_reg(:,1)-ptsA(:,1), ptsB_reg(:,2)-ptsA(:,2))
grid on
axis ij equal

%% Apply alignment
[B_reg, R_B_reg] = imwarp(B, R_B, tform);
figure, imshow(B_reg, R_B_reg)

%% Matches
figure, imshowpair(A, R_A, B_reg, R_B_reg)
plot_matches(ptsA, ptsB_reg)

%% Compare images
render_mode = 'diff';
figure, imshowpair(A, R_A, B, R_B, render_mode), title('Before')
figure, imshowpair(A, R_A, B_reg, R_B_reg, render_mode), title('After')