% Parameters
sec_nums = 52:149; % 1-149, 19 is missing
num_secs = length(sec_nums);
save_path = '/data/home/talmo/EMdata/W002/StitchData/sec_cache';

% Find matches
last_sec = [];
for i = 1:num_secs
    sec_num = sec_nums(i);
    fprintf('==== Processing section %d (%d/%d).\n', sec_num, i, num_secs)
    section_time = tic;
    
    % Load section
    try
        sec = load_sec(sec_num);
    catch
        warning('Could not load section %d.', sec_num)
        continue
    end
    
    % Register overview to last section
    try
        if ~isempty(last_sec)
            sec.overview_tform = register_overviews(sec, last_sec, 'show_registration', false);
        end
    catch err
        warning(err.message)
    end
    
    % Rough tile alignment
    sec = rough_align_tiles(sec, 'show_registration', false);
    
    % Detect features
    sec = detect_section_features(sec);
    
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
