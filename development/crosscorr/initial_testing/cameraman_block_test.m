%% Configuration
true_theta = 1.7;
true_offset = [0, 0];
true_tform = compose_tforms(make_tform('rotate', true_theta), make_tform('translate', true_offset));

% Load and transform image
A = imread('cameraman.tif'); R_A = imref2d(size(A));
[B, R_B] = imwarp(A, R_A, true_tform, 'FillValues', mean(A(:)));

%% Correlation
%B = padarray(B, true_offset, mean(B(:)), 'pre');
block_sz = [15, 15];
thetas = 0:0.5:5;
best_corr = 0;
best_trial = NaN;
best_theta = NaN;

for trial = 1:length(thetas)
    theta = thetas(trial);
    B_rot = imwarp(B, make_tform('rotate', -theta), 'FillValues', mean(B(:)));
    
    [rows, cols] = meshgrid(1:block_sz(1):size(B_rot, 1), 1:block_sz(2):size(B_rot, 2));
    locations = [rows(:), cols(:)];
    offsets = NaN(size(locations));
    best_corrs = NaN(length(locations), 1);
    for i = 1:length(locations)
        loc = locations(i, :);
        block = B_rot(loc(1):min(loc(1)+block_sz(1)-1, size(B_rot, 1)), ...
                  loc(2):min(loc(2)+block_sz(2)-1, size(B_rot, 2)));
        if std(double(block(:))) == 0
            continue
        end
        C = normxcorr2(block, A);
        [best_corrs(i), peak] = max(C(:));
        [peak(1), peak(2)] = ind2sub(size(C), peak);
        offset = peak - size(block);
        offsets(i, :) = offset - loc + [1, 1];
    end
    
    not_nan = ~isnan(offsets(:,1)) & ~isnan(offsets(:,2));
    mean_corr = mean(best_corrs(not_nan));
    
    if mean_corr > best_corr
        best_corr = mean_corr;
        best_trial = trial;
        best_theta = theta;
    end
    
    fprintf('<strong>Trial: %d</strong>\n', trial)
    fprintf('theta = %f\n', theta)
    %fprintf('max corr = %f\n', max(best_corrs))
    fprintf('mean corr = %f\n', mean_corr)
    %fprintf('mean offset = [%f, %f]\n', mean(offsets(not_nan, :)))
    %fprintf('median offset = [%f, %f]\n', median(offsets(not_nan, :)))
    %fprintf('std offset = [%f, %f]\n', std(offsets(not_nan, :)))
    fprintf('\n')
end

fprintf('\n<strong>Best trial: %d</strong>\n', best_trial)
fprintf('corr = %f\n', best_corr)
fprintf('theta = %f\n', best_theta)
fprintf('<strong>error = %f</strong>\n', true_theta - best_theta)

return
%% Visualize
quiver(locations(:,1), locations(:,2), offsets(:,1), offsets(:,2))
grid on
axis ij equal