%% Configuration
true_theta = 3.0;
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
scales = [0.1:0.1:1.0];
thetas = -5:0.5:5;

best_corr = 0;
best_scale = NaN;
best_theta = NaN;
best_translation = [NaN, NaN];

locA = [R_A.XWorldLimits(1), R_A.YWorldLimits(1)];
locB = [R_B.XWorldLimits(1), R_B.YWorldLimits(1)];

for s = 1:length(scales)
    scale = scales(s);
    A_scaled = imwarp(A, R_A, make_tform('scale', scale));
    [B_scaled, R_B_scaled] = imwarp(B, R_B, make_tform('scale', scale));
    backgroundA = mean(A_scaled(:));
    backgroundB = mean(B_scaled(:));
    %scale = size(B_reduced, 1) / size(B, 1);
    
    %pad_amount = round(size(A_scaled, 1) / 3);
    pad_amount = ceil(max(size(B_scaled) * sqrt(2) - size(A_scaled)));
    A_padded = padarray(A_scaled, [pad_amount pad_amount], backgroundA);
    
    %R_B_scaled = tform_spatial_ref(R_B, make_tform('scale', scale));
    
    scale_translations = zeros(length(thetas), 2);
    scale_corrs = zeros(length(thetas), 1);
    for i = 1:length(thetas)
        theta = thetas(i);
        
        tform = make_tform('rotation', -theta);
        [B_rot, R_B_rot] = imwarp(B_scaled, R_B_scaled, tform, 'FillValues', backgroundB);
        
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
        locA_scaled = (locA * scale);
        locB_rot = [R_B_rot.XWorldLimits(1), R_B_rot.YWorldLimits(1)];
        rel_trans_world = (locA_scaled - locB_rot) + rel_trans;
        
        % translation at 1.0 scale:
        translation = rel_trans_world * (1 / scale);
        
        
        %locB_rot = [R_B_rot.XWorldLimits(1), R_B_rot.YWorldLimits(1)] * (1 / scale);
        
        %translation = -(locA - locB_rot + rel_translation);
        
        scale_translations(i, :) = -translation;
        scale_corrs(i) = peak_corr;
        
        %fprintf('level = %d | scale = %f | theta = %f | peak_corr = %f\n', ...
        %    level, scale, theta, peak_corr)
    end
    
    [best_scale_corr, i] = max(scale_corrs);
    best_scale_theta = thetas(i);
    best_scale_translation = scale_translations(i, :);
    
    fprintf('scale = %f | best corr = %f | theta = %f | translation = [%f, %f]\n', scale, best_scale_corr, best_scale_theta, best_scale_translation)
    
    if best_scale_corr > best_corr
        best_corr = best_scale_corr;
        best_scale = scale;
        best_theta = best_scale_theta;
        best_translation = best_scale_translation;
    end
end

fprintf('best corr: %f\n', best_corr)
fprintf('scale: %.3f\n', best_scale)
fprintf('theta: %f | ', best_theta)
fprintf('true: %f\n', true_theta)
fprintf('translation: [%.1f, %.1f] | ', best_translation)
fprintf('true: [%.1f, %.1f]\n', true_translation)