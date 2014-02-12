% A simplified pipeline to test if different individual components are working.

%% Initialize sections
test_msg = 'Unit Test: Initializing Sections';
fprintf('%s\n%s\n', test_msg, repmat('=', 1, length(test_msg)))

% Test
overwrite_cache = false;
sections = load_some_sections(10, overwrite_cache);

% Check results
assert(length(sections) == 10, 'Failed: Did not load correct number of sections.');
for i = 1:length(sections)
    assert(~isempty(sections{i}.name), 'Failed: A section was not loaded properly.');
end

clear i test_msg overwrite_cache
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

%% Match features
test_msg = 'Unit Test: Matching features';
fprintf('%s\n%s\n', test_msg, repmat('=', 1, length(test_msg)))

% Test
features = stack.match_features(sections);

% Check results
assert(length(matches.x) == 10, 'Failed: Did not detect matches for all sections.');

clear i test_msg
fprintf('==> Passed unit test.\n\n')