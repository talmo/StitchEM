function features = load_features(sec)
%LOAD_FEATURES Loads cached features for a section.

% Initialize stuff
features = struct();
oldest_timestamp = now;
newest_timestamp = 0;

% Load from cached XY features
if exist(sec.xy_features_path, 'file')
    cache = load(sec.xy_features_path, 'features');
    features = cache.features;
    
    % Look for newest and oldest timestamp in the loaded features
    for i = 2:length(features)
        % Loop through seams
        for seam_name = fieldnames(features(i).xy)'
            seam_timestamp = datenum(features(i).xy.(seam_name{1}).timestamp);
            if seam_timestamp < oldest_timestamp
                oldest_timestamp = seam_timestamp;
            end
            if seam_timestamp > newest_timestamp
                newest_timestamp = seam_timestamp;
            end
        end
    end
end

% Do the same for the Z features
if exist(sec.z_features_path, 'file')
    cache = load(sec.z_features_path, 'features');
    
    % Merge structures if needed (i.e., if X features were loaded)
    if isfield(features, 'xy')
        features = cell2struct([struct2cell(features) ; struct2cell(cache.features)], {'xy', 'z'}, 1);
    else
        features = cache.features;
    end
    
    % Look for newest and oldest timestamp in the loaded features
    for i = 2:length(features)
        z_timestamp = datenum(features(i).z.timestamp);
        if z_timestamp < oldest_timestamp
            oldest_timestamp = z_timestamp;
        end
        if z_timestamp > newest_timestamp
            newest_timestamp = z_timestamp;
        end
    end
end

% Display warning messages about not loading XY or Z features if needed
if ~isfield(features, 'xy') && ~isfield(features, 'z')
    error(['No cached features were found to be loaded.\n' ...
        '\tSection data path: %s'], sec.data_path)
elseif ~isfield(features, 'xy')
    warning('No cached features were found for XY matching.')
elseif ~isfield(features, 'z')
    warning('No cached features were found for Z matching.')
end

% Display warning message if the oldest and newest timestamps were more
% than an hour apart (i.e., probably not from the same session)
if newest_timestamp - oldest_timestamp > datenum('1:00') - datenum('0:00')
    warning(['Some of the features loaded may have been detected in different sessions.\n' ...
        'This might mean that they were detected using different parameters.\n' ...
        'Run section.find_features() with parameters.overwrite = true to re-detect features.\n'...
        '\tOldest timestamp: %s\n' ...
        '\tNewest timestamp: %s'], oldest_timestamp, newest_timestamp)
end

% Display output message and log
msg = sprintf('Loaded features for %s (saved on %s).', sec.name, datestr(newest_timestamp));
fprintf('%s\n', msg)
stitch_log(msg, sec.data_path);


end

