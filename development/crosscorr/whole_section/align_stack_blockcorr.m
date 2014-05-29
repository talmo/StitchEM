if ~exist('status', 'var') || strcmp(status.step, 'finished_z'); status.step = 'blockcorr'; status.section = 1; end

for s = status.section:length(secs)
    fprintf('=== Aligning %s (<strong>%d/%d</strong>) in Z\n', secs{s}.name, s, length(secs))
    sec_timer = tic;
    
    % Fixed section
    if s == 1
        secs{s}.alignments.blockcorr = fixed_alignment(secs{s}, 'z');
        continue
    end
    
    % Section pair
    secA = secs{s - 1};
    secB = secs{s};
    
    % Matching
    secB.corr_matches = match_blockcorr(secA, secB);
    
    % Alignment
    secB.alignments.blockcorr = align_z_pair_cpd(secB, secB.corr_matches, 'z');
    
    % Save
    secB.runtime.blockcorr.time_elapsed = toc(sec_timer);
    secB.runtime.blockcorr.timestamp = datestr(now);
    secs{s} = secB;
end

% Save
disp('=== Saving sections to disk.');
filename = sprintf('%s_Secs%d-%d_blockcorr_aligned.mat', secs{1}.wafer, secs{1}.num, secs{end}.num);
save(get_new_path(fullfile(pwd, filename)), 'secs', 'status', '-v7.3')