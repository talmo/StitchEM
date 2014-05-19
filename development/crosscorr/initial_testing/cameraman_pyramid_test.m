%% Configuration
true_theta = 3.5234;
true_translation = [50, 100];
true_tform = compose_tforms(make_tform('translate', true_translation), make_tform('rotate', true_theta));

% Load and transform image
A = imread('cameraman.tif'); R_A = imref2d(size(A));
[B, R_B] = imwarp(A, R_A, true_tform, 'FillValues', mean(A(:)));

B = imnoise(B, 'gaussian');
%B = imnoise(B, 'localvar');
B = imnoise(B, 'poisson');
B = imnoise(B, 'salt & pepper');
B = imnoise(B, 'speckle');
%% Correlation
levels = 4;
thetas = -5:0.5:5;

best_corr = 0;
best_level = NaN;
best_theta = NaN;
best_translation = [NaN, NaN];

A_reduced = A;
B_reduced = B;

locA = [R_A.XWorldLimits(1), R_A.YWorldLimits(1)];
locB = [R_B.XWorldLimits(1), R_B.YWorldLimits(1)];

for level = 1:levels
    A_reduced = impyramid(A_reduced, 'reduce');
    B_reduced = impyramid(B_reduced, 'reduce');
    backgroundA = mean(A_reduced(:));
    backgroundB = mean(B_reduced(:));
    scale = size(B_reduced, 1) / size(B, 1);
    
    pad_amount = round(size(A_reduced, 1) / 3);
    A_padded = padarray(A_reduced, [pad_amount pad_amount], backgroundA);
    
    R_B_reduced = tform_spatial_ref(R_B, make_tform('scale', scale));
    
    level_translations = zeros(length(thetas), 2);
    level_corrs = zeros(length(thetas), 1);
    for i = 1:length(thetas)
        theta = thetas(i);
        
        tform = make_tform('rotation', -theta);
        [B_rot, R_B_rot] = imwarp(B_reduced, R_B_reduced, tform, 'FillValues', backgroundB);
        
        C = normxcorr2(B_rot, A_padded);
        %[peak_corr, peak] = max(C(:));
        [peak(1), peak(2), peak_corr] = findpeak(C, true);
        offset = peak - size(B_rot);
        
        % translation at this scale:
        rel_trans = fliplr(offset) - [pad_amount, pad_amount];
        
        % account for world locs:
        %tformA = make_tform('scale', scale);
        %R_A_reduced = tform_spatial_ref(R_A, tformA);
        %locA_padded = [R_A_reduced.XWorldLimits(1), R_A_reduced.YWorldLimits(1)];
        locA_reduced = (locA * scale);
        locB_rot = [R_B_rot.XWorldLimits(1), R_B_rot.YWorldLimits(1)];
        rel_trans_world = (locA_reduced - locB_rot) + rel_trans;
        
        % translation at 1.0 scale:
        translation = rel_trans_world * (1 / scale);
        
        
        %locB_rot = [R_B_rot.XWorldLimits(1), R_B_rot.YWorldLimits(1)] * (1 / scale);
        
        %translation = -(locA - locB_rot + rel_translation);
        
        level_translations(i, :) = -translation;
        level_corrs(i) = peak_corr;
        
        %fprintf('level = %d | scale = %f | theta = %f | peak_corr = %f\n', ...
        %    level, scale, theta, peak_corr)
    end
    
    [best_level_corr, i] = max(level_corrs);
    best_level_theta = thetas(i);
    best_level_translation = level_translations(i, :);
    
    fprintf('level = %d | best corr = %f | theta = %f | translation = [%f, %f]\n', level, best_level_corr, best_level_theta, best_level_translation)
    
    if best_level_corr > best_corr
        best_corr = best_level_corr;
        best_level = level;
        best_theta = best_level_theta;
        best_translation = best_level_translation;
    end
end

fprintf('best corr: %f\n', best_corr)
fprintf('level: %d\n', best_level)
fprintf('theta: %f | ', best_theta)
fprintf('true: %f\n', true_theta)
fprintf('translation: [%.1f, %.1f] | ', best_translation)
fprintf('true: [%.1f, %.1f]\n', true_translation)