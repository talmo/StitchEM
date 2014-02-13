% This set of unit tests verifies that stack level functions are working.
% CAREFUL: This will delete the entire data folder!

%% Set up
clear_cache % Deletes /StitchData folder
clear

wafer_path = '/data/home/talmo/EMdata/W002';

%% Initialize stack
test_msg = 'Unit Test: Initialize stack';
fprintf('%s\n%s\n', test_msg, repmat('=', 1, length(test_msg)))

sections = stack.initialize(wafer_path, true);

% Check results
assert(isa(sections, 'Stack'), 'Failed: Did not get a Stack instance.');

clear i test_msg
fprintf('==> Passed unit test.\n\n')

%% Detect features in stack
test_msg = 'Unit Test: Detect features in stack';
fprintf('%s\n%s\n', test_msg, repmat('=', 1, length(test_msg)))

features = stack.find_features(sections);

% Check results
assert(length(features) == sections.num_sections, 'Failed: Did not get same number of feature objects as sections.');

clear i test_msg
fprintf('==> Passed unit test.\n\n')
