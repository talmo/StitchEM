function sections = load_some_sections(secs_to_load, overwrite)
% Loads some section structures into 'sections' array for convenience.

%% Parameters
sections_path = '/data/home/talmo/EMdata/W002';
if nargin < 2
    overwrite = false;
end

%% Get section paths
paths = find_section_folders(sections_path, true);

% Truncate list
paths = paths(1:secs_to_load);

%% Initialize sections or load metadata
sections = cell(secs_to_load, 1);

fprintf('Loading %d sections...\n', secs_to_load); tic;
for i = 1:secs_to_load
    sections{i} = section.initialize(paths{i}, overwrite);
end
fprintf('Done loading sections. [%.2fs]\n', toc)
