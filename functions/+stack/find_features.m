function features = find_features(sections, parameters)
%FIND_FEATURES Finds features in a stack of sections.
% This is really just a wrapper for section.find_features().
import section.find_features

%% Parameters
if nargin < 2
    parameters = struct();
end

%% Find features in each section
% Initialize empty array of features
features = cell(length(sections), 1);

% Find features in each section
for i = 1:length(sections)
    features{i} = section.find_features(sections{i}, parameters);
end

end

