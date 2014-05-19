%% Configuration
true_theta = 0;
true_offset = [30, 30];
true_tform = compose_tforms(make_tform('rotate', true_theta), make_tform('translate', true_offset));

% Load and transform image
A = imread('cameraman.tif'); R_A = imref2d(size(A));
[B, R_B] = imwarp(A, R_A, true_tform);

% Angles to try
thetas = -10:1:10;

%% Region
% Define region in world coordinates
region_loc = [145, 35]; % [x, y]
region_res = [50, 50];   % [width, height]

% Get spatial reference
XLims_region = [region_loc(1), region_loc(1) + region_res(1)];
YLims_region = [region_loc(2), region_loc(2) + region_res(2)];
[IinB, JinB] = R_B.worldToSubscript(XLims_region, YLims_region);

% Crop from B
region = B(IinB(1):IinB(2)-1, JinB(1):JinB(2)-1);
R_region = imref2d(size(region), XLims_region, YLims_region);

%% Visualize
% imshowpair blending modes: 'falsecolor', 'montage', 'diff', 'blend'
figure, imshowpair(A, R_A, B, R_B, 'falsecolor'), title('A and B (unregistered)')
draw_poly(ref_bb(R_region));
figure, imshow(B, R_B), title('B and region')
draw_poly(ref_bb(R_region));
figure, imshow(region, R_region), title('region in B')
tilefigs

%% Cross-correlation
results = table();
for trial = 1:length(thetas)
    % Create rotation transform
    theta = thetas(trial);
    tform_rotate = make_tform('rotate', theta);
    
    % Rotate region
    a = mean(region(1:end, 1)); b = mean(region(1:end, end)); c = mean(region(1, 1:end)); d = mean(region(end, 1:end));
    [rotated_region, R_rotated_region] = imwarp(region, R_region, tform_rotate, 'FillValues', mean([a, b, c, d]));
    
    % Need to get the inscribed square
    % See: rectinrotatedrect
    % Also need to account for rotation not about the origin...
    %
    % fix this to work in all quadrants:
%     region_pts = tform_rotate.transformPointsForward(ref_bb(R_region)); % or should we use R_rotated_region's lims?
%     adjusted_pts = bsxadd(region_pts, -region_pts(1, :));
%     hyp = norm(adjusted_pts(4, :));
%     adj = max(adjusted_pts(:, 1));
%     rel_theta = acosd(adj/hyp); 
%     inscribed = rectinrotatedrect(region_res(1), region_res(2), -rel_theta);
    
    % viz
    %draw_poly(adjusted_pts)
    %draw_poly(inscribed)
    %axis equal
    
    % now get subscripts of inscribed from rotated image and use that
    
    %imshow(rotated_region, R_rotated_region)
    
    % Compute normalized cross-correlation
    C = normxcorr2(rotated_region, A);
    
    % Estimate location from peak of correlation
    % Note: The [i, j] location of the peak in C includes padding. In A,
    %   this coordinate is where the bottom-right pixel of rotated_region
    %   would be located.
    [max_C, max_C_idx] = max(C(:));
    [peak(1), peak(2)] = ind2sub(size(C), max_C_idx); % [i, j] in C
    
    % Adjust for padding to get top-left coordinate of region in A
    % Note: This can be negative!
    peak_A = peak - R_rotated_region.ImageSize + [1, 1]; % [i, j] in A
    
    % Get world coordinates of the peak
    [peak_loc(1), peak_loc(2)] = R_A.intrinsicToWorld(peak_A(2), peak_A(1)); % [x, y] in world
    
    % Get the world coordinates of the region after rotation
    region_loc_rotated = tform_rotate.transformPointsForward(region_loc);
    
    % Adjust for the nudging done by imwarp
    nudged_loc = [R_rotated_region.XWorldLimits(1), R_rotated_region.YWorldLimits(1)];
    nudge = nudged_loc - region_loc_rotated;
    
    % Compute offset after rotation
    offset = peak_loc - nudged_loc;
    
    % Save
    results = [results; table(trial, theta, offset, max_C, peak, peak_loc, nudge)];
end

[~, best_trial] = max(results.max_C);

% Display results
disp('Sorted results:')
disp(sortrows(results, 'max_C', 'descend'))

%% Calculate alignment
trial = best_trial;
theta = results.theta(trial);
offset = results.offset(trial, :);
peak_loc = results.peak_loc(trial, :);
nudge = results.nudge(trial, :);

% Calculate the transform implied by the cross-correlation
tform_rotate = make_tform('rotate', theta);
tform_translate = make_tform('translate', offset);
tform = compose_tforms(tform_rotate, tform_translate);

% Calculate error (should be 0 if exact angle)
prior_error = norm(region_loc + nudge - peak_loc);
post_error = norm(tform.transformPointsForward(region_loc) + nudge - peak_loc);
fprintf('Error: %f -> %f px\n', prior_error, post_error)

% Get bounding boxes
A_bb = ref_bb(R_A);
region_bb = ref_bb(R_region);
rotated_bb = tform.transformPointsForward(region_bb);
rotated_outer_bb = tform_bb2bb(region_bb, tform);
% = bsxadd(ref_bb(R_rotated), [dX, dY])
% = tform_translate.transformPointsForward(ref_bb(R_rotated))

% Apply alignment to image
[B_aligned, R_B_aligned] = imwarp(B, R_B, tform);

%% Visualize region
figure
imshow(A, R_A), hold on
draw_poly(A_bb, 'w0.1')
draw_poly(rotated_outer_bb, 'r0.2')
draw_poly(rotated_bb, 'b0.5')
plot(results.peak_loc(trial, 1), results.peak_loc(trial, 2), 'g*')
title(sprintf('A and region | trial = %d | theta = %f', trial, theta))

%% Visualize alignment
imshowpair(A, R_A, B_aligned, R_B_aligned, 'falsecolor')
title('A and B (registered)')
tilefigs

%% Visualize correlation surface
trial = best_trial;
theta = results.theta(trial);
peak = results.peak(trial, :);

rotated_region = imwarp(region, R_region, make_tform('rotate', theta));
C = normxcorr2(rotated_region, A);

figure, pcolor(C), title(sprintf('Cross-correlation | trial = %d | theta = %f', trial, theta))
shading flat, xlabel('Y offset after rotation'), ylabel('X offset after rotation'), hold on
plot(peak(1), peak(2), 'w*')
tilefigs

%% Visualize match
trial = best_trial;
peak_loc = results.peak_loc(trial, :);
nudge = results.nudge(trial, :);

figure, imshowpair(A, R_A, B, R_B)
plot_matches(peak_loc, region_loc + nudge)
draw_poly(rotated_outer_bb, 'g0.1')
draw_poly(rotated_bb, 'g0.5')
draw_poly(region_bb, 'm0.5')
title('Match')
tilefigs
