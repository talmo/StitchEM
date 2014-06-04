%% Wafers
num_secs = sum(cellfun(@length, wafers));
i = 1;

for w = 1:length(wafers)
    for s = 1:length(wafers{w})
        sec = wafers{w}{s};
        
        % Compile an observation
        obs.wafer = sec.wafer;
        obs.sec_num = sec.num;
        obs.num_tiles = sec.num_tiles;
        obs.xy = table();
        obs.xy.prior = sec.alignments.xy.meta.avg_prior_error;
        obs.xy.post = sec.alignments.xy.meta.avg_post_error;
        obs.xy.num_matches = sec.xy_matches.num_matches;
        obs.xy.runtime = sec.runtime.xy.time_elapsed;
        obs.z = table();
        obs.z.prior = sec.alignments.z.meta.avg_prior_error;
        obs.z.post = sec.alignments.z.meta.avg_post_error;
        if isfield(sec, 'z_matches')
            obs.z.num_matches = sec.z_matches.num_matches;
        else
            obs.z.num_matches = NaN;
        end
        obs.z.runtime = sec.runtime.z.time_elapsed;
        
        % Save
        if i == 1
            data = obs;
        else
            data(i) = obs;
        end
        i = i + 1;
    end
end

%% Save
save(get_new_path(fullfile(pwd, 'data.mat')), 'data')