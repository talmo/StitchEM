function matches = match_features(sections, features, parameters)
%FIND_MATCHES Finds matching pairs for all features in a stack of sections.

% This should basically be  wrapper for the XY versus Z matching steps.

%% XY Matching
% Loop through sections
for i = 1:length(sections)
    if isempty(features{i})
        features{i} = section.find_features(sections{i}, parameters);
    end
    section_matches = section.match_features(sections{i}, features{i}, parameters);
    % save this to sections{i}.xy_matches_path
end

%% Z Matching
% Loop through section pairs

    % Call stack.find_z_matches() on each pair?

end

