%% Configuration
waferA = 'S2-W002_Secs1-149_z_aligned.mat';
waferB = 'S2-W003_Secs1-169_z_aligned.mat';

% Load data
cache = load(fullfile(cachepath, waferA), 'secs');
secsA = cache.secs;
cache = load(fullfile(cachepath, waferB), 'secs');
secsB = cache.secs;
clear cache
disp('Loaded sections.')

%% End sections
secA = secsA{end};
secB = secsB{1};

% Compose previous
secB.alignments.prev_stack_z = compose_alignments(secA, {'prev_z', 'z'}, secB, 'z');

%% Visualize
figure
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'prev_stack_z', 'g0.1')

%% Render
scale = 0.125;
[A, RA] = render_section(secA, 'z');
A = imresize(A, scale);
[B, RB] = render_section(secB, 'prev_stack_z');
B = imresize(B, scale);

% CLAHE
A = adapthisteq(A);
B = adapthisteq(B);

%% Rough align
% Find features
featsA = detect_surf_features(A, 'MetricThreshold', 5000, 'pre_scale', scale, 'detection_scale', 0.075);
featsB = detect_surf_features(B, 'MetricThreshold', 5000, 'pre_scale', scale, 'detection_scale', 0.075);
fprintf('Found %d and %d features.\n', height(featsA), height(featsB))

% Global points
[featsA.global_points(:,1), featsA.global_points(:,2)] = RA.intrinsicToWorld(featsA.local_points(:,1), featsA.local_points(:,2));
[featsB.global_points(:,1), featsB.global_points(:,2)] = RB.intrinsicToWorld(featsB.local_points(:,1), featsB.local_points(:,2));

% Match
nnr_matches = nnr_match(featsA, featsB, 'out', 'rows-nodesc');

% Filter
[inliers, outliers] = gmm_filter(nnr_matches);
matches.A = nnr_matches.A(inliers, :);
matches.B = nnr_matches.B(inliers, :);
matches.outliers.A = nnr_matches.A(outliers, :);
matches.outliers.B = nnr_matches.B(outliers, :);
fprintf('Found %d/%d matches. Error: %fpx/match\n', height(matches.A), height(nnr_matches.A), rownorm2(matches.B.global_points - matches.A.global_points))

% Align
secA.alignments.stack_z = fixed_alignment(secA, 'z');
secB.alignments.stack_z = align_z_pair_cpd(secB, matches, 'prev_stack_z');

%% Matches
figure
plot_section(secA, 'stack_z', 'r0.1')
plot_section(secB, 'prev_stack_z', 'g0.1')
plot_matches(matches)

%% Displacements
figure
plot_displacements(matches)

%% Alignment
figure
plot_section(secA, 'stack_z', 'r0.1')
plot_section(secB, 'stack_z', 'g0.1')

%% Render aligned
scale = 0.125;
R = stack_ref({secA, secB}, 'stack_z');
A = imresize(render_section(secA, 'stack_z', R), scale);
B = imresize(render_section(secB, 'stack_z', R), scale);

%% Visualize
figure
imshowpair(A, B)