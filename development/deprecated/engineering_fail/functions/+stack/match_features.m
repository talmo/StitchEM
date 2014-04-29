function matches = match_features(sections, parameters)
%FIND_MATCHES Finds matching pairs for all features in a stack of sections.

%% Process parameters
% Defaults
params.z_neighbors = [-1 1];

% TODO: Overwrite defaults with inputted parameters

%% XY Matching
fprintf('Matching features in stack of %d sections...\n', sections.num_sections)
tic;

% Initialize empty array of XY matches
matches.xy = cell(length(sections), 1);

% Loop through sections
for i = sections.min_section_number:sections.max_section_number
    % Check if section and features exist in stack
    try
        sec = sections.get_section(i);
        feats = sections.get_features(i);
    catch
        warning('Could not find metadata or features for section %d in stack.', i)
        continue
    end
    
    % Match the features for this section
    matches.xy{i} = section.match_xy_features(sec, feats);
end

%% Z Matching
z_matches = cell(sections.max_section_number, 1); % Initialize empty array of Z matches
matched_section_pairs = cell(sections.max_section_number, 1); % Keep track of section pairs we've matched already

% Loop through sections
for i = sections.min_section_number:sections.max_section_number
    % Check if section and features exist in stack
    try
        secA = sections.get_section(i);
        featsA = sections.get_features(i);
    catch
        warning('Could not find metadata or features for section %d in stack.', i)
        continue
    end
    
    % Loop through adjacent sections
    for e = params.z_neighbors + i
        % Check if we've matched this section pair
        if any(cellfun(@(x) isequal(x, [i e]) | isequal(x, [e i]), matched_section_pairs))
            continue
        end
        
        % Check if section and features exist in stack
        if e < sections.min_section_number || e > sections.max_section_number
            continue
        end
        try
            secB = sections.get_section(e);
            featsB = sections.get_features(e);
        catch
            warning('Could not find metadata or features for section %d in stack.', e)
            continue
        end
        
        % Match the features for the section pair
        try
            idx = find(cellfun('isempty', z_matches), 1); % Find first empty cell
            z_matches{idx} = section.match_z_features(secA, featsA, secB, featsB);
        catch
            warning('Could not find matches between sections %s and %s.', secA.name, secB.name)
            continue
        end
        
        % Keep track of matched section pairs
        matched_section_pairs{i} = [i e];
    end
end

% Remove empty cells
z_matches(cellfun('isempty', z_matches)) = [];

%% Save Z matches to structure and cache
save(sections.z_matches_path, 'z_matches');

% Save to the matches structure
matches.z = z_matches;

fprintf('Done matching features for stack. [%.2fs]\n', toc)
    
end

