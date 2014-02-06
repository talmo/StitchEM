% A simplified pipeline to test if different components are working.

%% Load sections
test_msg = 'Unit Test: Loading Sections';
fprintf('%s\n%s\n', test_msg, repmat('=', 1, length(test_msg)))

% Test
sections = load_some_sections(10, true);

% Check results
assert(length(sections) == 10, 'Failed: Did not load correct number of sections.');
for i = 1:length(sections)
    assert(~isempty(sections{i}.name), 'Failed: A section was not loaded properly.');
end

clear i test_msg
fprintf('==> Passed unit test.\n\n')

%% Find features
test_msg = 'Unit Test: Finding features';
fprintf('%s\n%s\n', test_msg, repmat('=', 1, length(test_msg)))

% Test
features = stack.find_features(sections);

% Check results
assert(length(features) == 10, 'Failed: Did not detect features for all sections.');

clear i test_msg
fprintf('==> Passed unit test.\n\n')