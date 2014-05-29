% Crops a stack of rendered sections to a specified region.

%% Parameters
renders_path = 'renders/sec22-149_matches_2014-04-09_high_lambda'; % folder with the rendered sections
crops_path = 'renders/sec22-149_matches_2014-04-09_high_lambda/crops'; % output folder
sec_nums = 22:149; % sections to crop
pos = [25000, 25000]; % XY of coordinate of cropped region
sz = 500; % size of cropped region

%% Save to single multi-page TIFF file
stack_crop_time = tic;
num_secs = length(sec_nums);
region_stack = zeros(sz, sz, num_secs, 'uint8');
parfor i = 1:num_secs
    path = sprintf('%s/sec%d_1x.tif', renders_path, sec_nums(i));
    region_stack(:, :, i) = imread(path, 'PixelRegion', {[pos(1), pos(1) + sz - 1], [pos(2), pos(2) + sz - 1]});
end

% Save to single TIF file
tif_path = sprintf('%s/sec%d-%d_[%d,%d].tif', crops_path, sec_nums(1), sec_nums(end), pos(1), pos(2));
for i = 1:num_secs
    imwrite(region_stack(:,:,i), tif_path, 'WriteMode', 'append')
end
fprintf('Cropped %d sections and saved to stack. [%.2fs]\n', num_secs, toc(stack_crop_time))

%% Save to individual TIFF files
crop_save_time = tic;
num_secs = length(sec_nums);
parfor i = 1:num_secs
    s = sec_nums(i);
    render_path = sprintf('%s/sec%d_1x.tif', renders_path, s);
    tif_path = sprintf('%s/sec%d.tif', crops_path, s);
    imwrite(imread(render_path, 'PixelRegion', {[pos(1), pos(1) + sz - 1], [pos(2), pos(2) + sz - 1]}), tif_path);
end
fprintf('Cropped %d sections and saved to files. [%.2fs]\n', num_secs, toc(crop_save_time))