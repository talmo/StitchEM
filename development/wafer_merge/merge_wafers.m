%% Configuration
waferA = 'S2-W002_Secs1-149_z_aligned.mat';
waferB = 'S2-W003_Secs1-169_z_aligned.mat';

% Load data
cache = load(fullfile(cachepath, waferA), 'secs');
secsA = cache.secs;
cache = load(fullfile(cachepath, waferB), 'secs');
secsB = cache.secs;
wafers = {secsA, secsB};
clear cache secsA secsB
disp('Loaded wafers.')

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
