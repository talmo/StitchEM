%% Parameters
base_folder = 'W002';
%sec_nums = 1:169;
%sec_nums = unique(cellfun(@(sec) sec.num, secs));
sec_nums = get_path_info(waferpath, 'sec_nums');

%sec_nums(sec_nums == 13) = [];
%sec_nums(sec_nums == 14) = [];

%sec_nums = sec_nums(1:14);
sec_nums = sec_nums(65:75);

rel_tforms = cell(length(sec_nums), 1);
tforms = cell(length(sec_nums), 1);
num_inliers = zeros(length(sec_nums) - 1, 1);
filtered_errors = zeros(length(sec_nums) - 1, 1);
aligned_errors = zeros(length(sec_nums) - 1, 1);

%% Align
total_align_time = tic;
start_at = 1;
if exist('stopped_at', 'var')
    start_at = stopped_at;
end
for s = start_at:length(sec_nums)
    fprintf('== Aligning section %d (<strong>%d/%d</strong>)\n', sec_nums(s), s, length(sec_nums))
    stopped_at = s;
    
    if s == 1
        disp('Keeping section fixed.')
        tforms{s} = affine2d();
        continue
    end
    
    sec_time = tic;
    
    % Load images
%     A = adapthisteq(imread(sprintf('%s/S2-W002_Sec%d_Montage.tif', base_folder, sec_nums(s - 1))));
%     B = adapthisteq(imread(sprintf('%s/S2-W002_Sec%d_Montage.tif', base_folder, sec_nums(s))));
    A = imread(sprintf('%s/S2-W002_Sec%d_Montage.tif', base_folder, sec_nums(s - 1)));
    B = imread(sprintf('%s/S2-W002_Sec%d_Montage.tif', base_folder, sec_nums(s)));
    
    % Find matches
    [ptsA, ptsB] = xcorr_match(A, B, 'grid_sz', [100, 100], 'block_sz', [150, 150]);
    
    % Filter matches
    try
        [ptsA, ptsB] = gmm_filter(ptsA, ptsB);
    catch
        [ptsA, ptsB] = geomedian_filter(ptsA, ptsB);
    end
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
fprintf('Estimating stack spatial reference...')
stack_ref_time = tic;

% Find the output spatial reference of each section
Rs = cell(length(sec_nums), 1);
for s = 1:length(sec_nums)
    filepath = sprintf('%s/S2-W002_Sec%d_Montage.tif', base_folder, sec_nums(s));
    Rs{s} = tform_spatial_ref(imref2d(imsize(filepath)), tforms{s});
end

% Merge them to find the spatial reference of the whole stack
R_stack = merge_spatial_refs(Rs);
fprintf(' Done. [%.2fs]\n', toc(stack_ref_time))

% Create output folder
output_folder = create_folder([base_folder '_aligned']);

% Render each section
total_render_time = tic;
for s = 1:length(sec_nums)
    fprintf('Rendering section %d (<strong>%d/%d</strong>)...', sec_nums(s), s, length(sec_nums))
    sec_render_time = tic;
    
    % Load and transform image
    filename = sprintf('S2-W002_Sec%d_Montage.tif', sec_nums(s));
    filepath = [base_folder filesep filename];
    sec_img = imwarp(imread(filepath), tforms{s}, 'OutputView', R_stack);
    sec_img = adapthiseq(sec_img);
    
    % Save
    imwrite(sec_img, [output_folder filesep filename])
    
    fprintf('Done. [%.2fs]\n', toc(sec_render_time))
end
fprintf('<strong>Done rendering all sections.</strong> [%.2fs]\n', toc(total_render_time))