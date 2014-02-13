% This set of unit tests verifies that stack level functions are working.
% 

clear
wafer_path = '/data/home/talmo/EMdata/W002';

%% Load stack
test_msg = 'Unit Test: Load stack';
fprintf('%s\n%s\n', test_msg, repmat('=', 1, length(test_msg)))

sections = stack.load(wafer_path);

% Check results
assert(isa(sections, 'Stack'), 'Failed: Did not get a Stack instance.');

clear i test_msg
fprintf('==> Passed unit test.\n\n')

%% Load features
test_msg = 'Unit Test: Load features';
fprintf('%s\n%s\n', test_msg, repmat('=', 1, length(test_msg)))

features = stack.load_features(sections);

% Check results
assert(length(features) == sections.num_sections, 'Failed: Did not get same number of feature objects as sections.');

clear i test_msg
fprintf('==> Passed unit test.\n\n')