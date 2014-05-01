%% Basic overwrites
defaults.display_montage = false;
defaults.display_matches = false;
defaults.display_merge = false;
defaults.highlow_filter = false;
defaults.median_filter = false;


%% Run different tests
run_name = 'defaults';
try
    tic;
    params = defaults;
    
    register_stack(run_name, params);
    fprintf('Run %s finished in %.2fs.\n\n\n', run_name, toc)
catch
    fprintf('Run %s failed.\n', run_name)
end


run_name = 'median_filter_6px';
try
    tic;
    params = defaults;
    
    params.median_filter = true;
    params.median_filter_radius = 6; % default = 3
    
    register_stack(run_name, params);
    fprintf('Run %s finished in %.2fs.\n\n\n', run_name, toc)
catch
    fprintf('Run %s failed.\n', run_name)
end


run_name = 'median_filter_12px';
try
    tic;
    params = defaults;
    
    params.median_filter = true;
    params.median_filter_radius = 12; % default = 3
    
    register_stack(run_name, params);
    fprintf('Run %s finished in %.2fs.\n\n\n', run_name, toc)
catch
    fprintf('Run %s failed.\n', run_name)
end

run_name = 'highlow_filter';
try
    tic;
    params = defaults;
    
    params.highlow_filter = true; % [180, 210] default
    
    register_stack(run_name, params);
    fprintf('Run %s finished in %.2fs.\n\n\n', run_name, toc)
catch
    fprintf('Run %s failed.\n', run_name)
end


run_name = 'highlow_filter_wider';
try
    tic;
    params = defaults;
    
    params.highlow_filter = true;
    params.high_threshold = 230;
    params.low_threshold = 125;
    
    register_stack(run_name, params);
    fprintf('Run %s finished in %.2fs.\n\n\n', run_name, toc)
catch
    fprintf('Run %s failed.\n', run_name)
end