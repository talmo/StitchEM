%% Configuration

A = imread('control/S2-W003_Sec8_Montage.tif');
R_A = imref2d(size(A));
B = imread('control/S2-W003_Sec9_Montage.tif');
R_B = imref2d(size(B));

%% Correlation
scales = [0.125, 0.25, 0.5];
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
fprintf('theta: %f\n', best_theta)
fprintf('translation: [%.1f, %.1f]\n', best_translation)

%% Align
tform = compose_tforms(make_tform('rotate', -best_theta), make_tform('translate', -best_translation));
[Breg, R_Breg] = imwarp(B, R_B, tform, 'FillValues', mean(B(:)));



%% Visualize
figure
imshowpair(A, R_A, B, R_B, 'falsecolor')
figure
imshowpair(A, R_A, Breg, R_Breg, 'falsecolor')