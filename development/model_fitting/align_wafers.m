wafers = {'S2-W004'};
%wafers = {'S2-W007', 'S2-W008'};
for w = 1:length(wafers)
    try
        % Parameters
        wafer = wafers{w};
    
        % Stack
        waferpath(['/mnt/data0/ashwin/07122012/' wafer])
        info = get_path_info(waferpath);
        sec_nums = info.sec_nums;

        % Run parameters
        overwrite_secs = false; % errors out if the current section was already aligned
        stop_after = 'z'; % 'xy', or 'z'

        % Load defaults
        default_params

        % Custom parameters
        % See default_params for presets

        % Run
        align_stack_xy
        align_stack_z
    catch
        fprintf('<strong>Failed on wafer %s, skipping.</strong>\n', wafer)
        clearvars -except w wafers
        continue
    end
end