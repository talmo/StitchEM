%% Parameters
sec_nums = 1:100;
base_folder = '0.45x,lsq';

%% Align
rel_tforms = cell(length(sec_nums), 1);
tforms = cell(length(sec_nums), 1);
num_inliers = zeros(length(sec_nums) - 1, 1);
filtered_errors = zeros(length(sec_nums) - 1, 1);
aligned_errors = zeros(length(sec_nums) - 1, 1);
total_align_time = tic;
for s = 1:length(sec_nums)
    fprintf('== Aligning section %d (<strong>%d/%d</strong>)\n', sec_nums(s), s, length(sec_nums))
    
    if s == 1
        disp('Keeping section fixed.')
        tforms{s} = affine2d();
        continue
    end
    
    sec_time = tic;
    
    % Load images
    A = imread(sprintf('%s/S2-W003_Sec%d_Montage.tif', base_folder, sec_nums(s - 1)));
    B = imread(sprintf('%s/S2-W003_Sec%d_Montage.tif', base_folder, sec_nums(s)));
    
    % Find matches
    [ptsA, ptsB] = xcorr_match(A, B, 'grid_sz', [100, 100], 'block_sz', [150, 150]);
    
    % Filter matches
    [ptsA, ptsB] = gmm_filter(ptsA, ptsB);
    filtered_errors(s - 1) = rownorm2(ptsB - ptsA);
    num_inliers(s - 1) = length(ptsA);
    
    % Align
    rel_tforms{s} = cpd_solve(ptsA, ptsB, 'affine');
    tforms{s} = compose_tforms(tforms{s - 1}, rel_tforms{s});
    aligned_errors(s - 1) = rownorm2(rel_tforms{s}.transformPointsForward(ptsB) - ptsA);
    
    fprintf('Done aligning section %d. [%.2fs]\n', sec_nums(s), toc(sec_time))
end
fprintf('<strong>Done aligning all sections.</strong> [%.2fs]\n\n', toc(total_align_time))

%% Render
fprintf('Estimating stack spatial reference...\n')
stack_ref_time = tic;

% Find the output spatial reference of each section
Rs = cell(length(sec_nums), 1);
for s = 1:length(sec_nums)
    filepath = sprintf('%s/S2-W003_Sec%d_Montage.tif', base_folder, sec_nums(s));
    Rs{s} = tform_spatial_ref(imref2d(imsize(filepath)), tforms{s});
end

% Merge them to find the spatial reference of the whole stack
R_stack = merge_spatial_refs(Rs);
fprintf('Done. [%.2fs]\n', toc(stack_ref_time))

% Create output folder
output_folder = create_folder([base_folder '_aligned']);

% Render each section
total_render_time = tic;
for s = 1:length(sec_nums)
    fprintf('Rendering section %d (<strong>%d/%d</strong>)...', sec_nums(s), s, length(sec_nums))
    sec_render_time = tic;
    
    % Load and transform image
    filename = sprintf('S2-W003_Sec%d_Montage.tif', sec_nums(s));
    filepath = [base_folder filesep filename];
    sec_img = imwarp(imread(filepath), tforms{s}, 'OutputView', R_stack);
    
    % Save
    imwrite(sec_img, [output_folder filesep filename])
    
    fprintf('Done. [%.2fs]\n', toc(sec_render_time))
end
fprintf('<strong>Done rendering all sections.</strong> [%.2fs]\n', toc(total_render_time))