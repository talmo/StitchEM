function features = load_features(sections)
%LOAD_FEATURES Loads cached features in a stack of sections.
% Takes a cell array of section structures.
%
% This is really just a wrapper for section.load_features().
import section.load_features

if isa(sections, 'Stack')
    sections = sections.sections;
end

%% Find features in each section
% Initialize empty array of features
features = cell(length(sections), 1);

fprintf('Loading features in stack of %d sections...\n', length(sections))
tic;

% Find features in each section
for i = 1:length(sections)
    features{i} = section.load_features(sections{i});
end

fprintf('Done loading features for stack. [%.2fs]\n', toc)

end

