%% Set section pair
s = 140; % set to status.section to use current section
secA = secs{s - 1};
secB = secs{s};

%% Plot features (secA)
feature_set = 'base_z';
pointsA = cell2mat(cellfun(@(t) t.global_points,  secA.features.(feature_set).tiles, 'UniformOutput', false));

plot_section(secA, secA.features.(feature_set).meta.base_alignment, 'r0.1');
plot_features(pointsA)

%% Plot features (secB)
feature_set = 'z';
pointsB = cell2mat(cellfun(@(t) t.global_points,  secB.features.(feature_set).tiles, 'UniformOutput', false));

plot_section(secB, secB.features.(feature_set).meta.base_alignment, 'g0.1');
plot_features(pointsB)

%% Matches
figure
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'prev_z', 'g0.1')
plot_matches(secB.z_matches)

%% Match Displacements
figure
plot_displacements(secB.z_matches)

%% Alignment
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'z', 'g0.1')

%% Render preview
% R  = stack_ref({secA, secB}, 'z');
% preview = render_preview(secB, 0.025, 'z', R);
% imshow(preview)