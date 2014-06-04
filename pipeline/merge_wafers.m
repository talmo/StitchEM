%% Configuration
wafer_cachefiles = {'S2-W002_Secs1-149_z_aligned.mat', 'S2-W003_Secs1-169_z_aligned.mat', 'S2-W004_Secs1-173_z_aligned.mat', 'S2-W005_Secs1-174_z_aligned.mat'};
output_name = 'S2-W002-W005_merged_z';

%% Load data
num_wafers = length(wafer_cachefiles);
fprintf('Loading %d wafers from cache.\n', num_wafers)
load_time = tic;
wafers = cell(num_wafers, 1);
for w = 1:num_wafers
    tic;
    cache = load(fullfile(cachepath, wafer_cachefiles{w}), 'secs');
    wafers{w} = cache.secs;
    fprintf('Loaded wafer <strong>%s</strong> (%d/%d). [%.2fs]\n', wafers{w}{1}.wafer, w, num_wafers, toc)
    clear cache
end
fprintf('Finished loading wafers. [%.2fs]\n', toc(load_time))

%% Merge
for w = 1:length(wafers)
    % First wafer is the reference
    if w == 1
        for s = 1:length(wafers{w})
            wafers{w}{s}.alignments.stack_z = fixed_alignment(wafers{w}{s}, 'z', 0);
        end
        fprintf('Keeping <strong>%s</strong> fixed.\n', wafers{w}{1}.wafer)
        continue
    end
    
    secsA = wafers{w - 1};
    secsB = wafers{w};
    fprintf('Aligning <strong>%s</strong> to <strong>%s</strong>.\n', secsB{1}.wafer, secsA{1}.wafer)
    
    % Get end sections
    secA = secsA{end};
    secB = secsB{1};

    % Compose with previous
    secB.alignments.prev_stack_z = compose_alignments(secA, {'prev_z', 'z'}, secB, 'z');
    
    % Align
    secB.alignments.stack_z = align_rendered_pair(secA, 'stack_z', secB, 'prev_stack_z');
    
    % Propagate to the rest of the wafer
    for s = 1:length(secsB)
        secsB{s}.alignments.stack_z = compose_alignments(secB, {'prev_stack_z', 'stack_z'}, secsB{s}, 'z');
    end
    
    % Save
    wafers{w} = secsB;
    
    fprintf('Aligned <strong>%s</strong> to <strong>%s</strong>.\n', secsB{1}.wafer, secsA{1}.wafer)
    clear secsA secsB secA secB
end

%% Save
output_path = get_new_path(fullfile(cachepath(), [output_name '.mat']));
fprintf('Saving wafers to %s... ', output_path)
save_time = tic;
save(output_path, 'wafers')
fprintf('Done. [%.2fs]\n', toc(save_time));