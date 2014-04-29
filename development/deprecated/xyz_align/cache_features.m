% Detects features across a stack of sections and saves them to disk.
% Note: Doesn't save the images.

% Parameters
wafer_path = '/data/home/talmo/EMdata/S2-W003';
sec_nums = 1:169;
num_secs = length(sec_nums);
save_path = './S2-W003_data/features';

% Keep track of failures and statistics
couldnt_load = {};
failed_overview_registration = {};
failed_feature_detection = {};
num_grid_aligned = zeros(num_secs, 1);
num_features_xy = cell(num_secs, 1);
num_features_z = cell(num_secs, 1);

% Detect features
last_sec = [];
for i = 1:num_secs
    sec_num = sec_nums(i);
    fprintf('==== Processing section %d (%d/%d).\n', sec_num, i, num_secs)
    section_time = tic;
    
    % Load section
    try
        sec = load_sec(sec_num, 'wafer_path', wafer_path, 'overwrite', true);
    catch
        warning('Could not load section %d.', sec_num)
        couldnt_load{end + 1} = sec_num;
        continue
    end
    
    % Register overview to last section
    try
        if ~isempty(last_sec)
            sec.overview_tform = register_overviews(sec, last_sec, 'show_registration', false);
        end
    catch err
        warning(err.message)
        failed_overview_registration{end + 1} = [sec.num, last_sec.num];
    end
    
    % Rough tile alignment
    sec = rough_align_tiles(sec, 'show_registration', false);
    num_grid_aligned(sec.num) = length(sec.grid_aligned);
    
    % Detect features
    try
        [sec, num_features_xy{sec.num}, num_features_z{sec.num}] = detect_section_features(sec);
    catch err
        warning(err.message)
        failed_feature_detection{end + 1} = sec.num;
    end
    
    % Save features and section structure to disk without images
    overview = sec.img.overview; sec.img = [];
    if ~exist(save_path, 'dir')
        mkdir(save_path)
    end
    save(fullfile(save_path, sprintf('%s.mat', sec.name)), 'sec')
    
    % Cache section
    last_sec = sec;
    last_sec.img.overview = overview;
    
    fprintf('== Done processing section %d (%d/%d). [%.2fs]\n\n', sec.num, i, num_secs, toc(section_time))
end

%% Save statistics and run data
save(fullfile(save_path, sprintf('sec%d-%d_feature_detection_data.mat', sec_nums(1), sec_nums(end))), ...
    'couldnt_load', 'failed_overview_registration', 'failed_feature_detection', 'num_grid_aligned', 'num_features_xy', 'num_features_z')
