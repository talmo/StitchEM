% This set of unit tests (naively) ensures that the following are working:
% - Section initialization
% - Section loading from cache
% - Feature detection (XY and Z)
% - Feature loading from cache
%
% WARNING: Running these unit tests will be very CPU intensive due to
% the feature detection routines.
%
% This script requires that load_some_sections() be in the path, e.g., in
% the same folder as this script.
%
% Consider running clear_cache to delete the StitchData folder before doing
% unit tests.
%
% Functions/scripts tested:
%   /functions/+processing:
%       - processing.find_features(): Does the heavy lifting for feature
%       detection. Works directly with the raw image data.
%
%   /functions/+section:
%       - section.initialize(): Initializes a section structure.
%       - section.load(): Loads a saved section structure.
%       - section.find_features(): Bootstraps processing.find_features()
%       for each tile in the section.
%
%   /functions/+stack:
%       - stack.find_features(): Bootstraps section.find_features() for
%       each section in a cell array of sections.
%       - stack.load_features(): Loads the saved features from cache.
%
%   /functions/utilities:
%       - find_section_folders(): Parses a directory listing to find
%       sections folders in (presumably) a wafer folder.
%       - stitch_log(): Logs timestamped messages to StitchData/stitch.log.
%

clear
num_sections_to_test = 3; % Testing with more than 10 sections is not recommended!

%% Initialize sections
test_msg = 'Unit Test: Initializing sections';
fprintf('%s\n%s\n', test_msg, repmat('=', 1, length(test_msg)))

% Test
overwrite_cache = true;
sections = load_some_sections(num_sections_to_test, overwrite_cache);

% Check results
assert(length(sections) == num_sections_to_test, 'Failed: Did not load correct number of sections.');
for i = 1:length(sections)
    assert(~isempty(sections{i}.name), 'Failed: A section was not loaded properly.');
end

clear i test_msg overwrite_cache sections
fprintf('==> Passed unit test.\n\n')

%% Load sections
% This unit test is the same as the last one but with the overwrite flag
% set to false so the cached data is loaded instead.
test_msg = 'Unit Test: Loading saved sections';
fprintf('%s\n%s\n', test_msg, repmat('=', 1, length(test_msg)))

% Test
overwrite_cache = false;
sections = load_some_sections(num_sections_to_test, overwrite_cache);

% Check results
assert(length(sections) == num_sections_to_test, 'Failed: Did not load correct number of sections.');
for i = 1:length(sections)
    assert(~isempty(sections{i}.name), 'Failed: A section was not loaded properly.');
end

clear i test_msg overwrite_cache
fprintf('==> Passed unit test.\n\n')


%% Find features
% This detects features in the sections we just initialized/loaded.
% CAREFUL: This test might take a while to run on many sections!

test_msg = 'Unit Test: Finding features';
fprintf('%s\n%s\n', test_msg, repmat('=', 1, length(test_msg)))

% Test
features = stack.find_features(sections);

% Check results
assert(length(features) == num_sections_to_test, 'Failed: Did not detect features for all sections.');

clear i test_msg features
fprintf('==> Passed unit test.\n\n')

%% Load features
% This test calls the same function as the last one but this time it should
% load the saved features from cache.

test_msg = 'Unit Test: Loading saved features';
fprintf('%s\n%s\n', test_msg, repmat('=', 1, length(test_msg)))

% Test
features = stack.find_features(sections);

% Check results
assert(length(features) == num_sections_to_test, 'Failed: Did not load features for all sections.');

clear i test_msg
fprintf('==> Passed unit test.\n\n')

