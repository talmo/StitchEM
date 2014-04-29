%% Initialize
match_sets = dir('match_sets/sec*.mat');
current_set = 6;
match_set = match_sets(current_set).name;
tic; load(sprintf('match_sets/%s', match_set))
fprintf('Match set %s: Loaded %d matches from cache [%.2fs].\n', match_set, height(matchesA), toc)
lambda = 0.0189281615401724;
secs = align_section_stack(secs, matchesA, matchesB, 'lambda', lambda);

%% Test
render_stack_cropped(secs)