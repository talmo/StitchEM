%% Configuration
secA = 102;
secB = 103;
tile = 1;
scale = 0.125;

%% Control
% Load
A = imload_tile(secA, tile, scale);
B = imload_tile(secB, tile, scale);

% Detect features
featsA = detect_surf_features(A);
featsB = detect_surf_features(B);

% Match
nnr_matches = nnr_match(featsA, featsB, 'out', 'local_points');
inliers = gmm_filter(nnr_matches);

% Align
[tform, aligned_error] = cpd_solve(inliers, 'affine', false);

% Metrics
num_nnr_matches = length(nnr_matches.A);
nnr_error = rownorm2(nnr_matches.B - nnr_matches.A);
num_inlier_matches = length(inliers.A);
inlier_error = rownorm2(inliers.B - inliers.A);

% Output
disp('<strong>Control:</strong>')
fprintf('NNR Error: %f px/match (n = %d matches)\n', nnr_error, num_nnr_matches)
fprintf('Inliers Error: %f px/match (n = %d matches)\n', inlier_error, num_inlier_matches)
fprintf('Aligned Error: %f px/match\n', aligned_error)

%% CLAHE
% Load
A = imload_tile(secA, tile, scale);
B = imload_tile(secB, tile, scale);

% Apply CLAHE
A = adapthisteq(A);
B = adapthisteq(B);

% Detect features
featsA = detect_surf_features(A);
featsB = detect_surf_features(B);

% Match
nnr_matches = nnr_match(featsA, featsB, 'out', 'local_points');
inliers = gmm_filter(nnr_matches);

% Align
[tform, aligned_error] = cpd_solve(inliers, 'affine', false);

% Metrics
num_nnr_matches = length(nnr_matches.A);
nnr_error = rownorm2(nnr_matches.B - nnr_matches.A);
num_inlier_matches = length(inliers.A);
inlier_error = rownorm2(inliers.B - inliers.A);

% Output
disp('<strong>CLAHE:</strong>')
fprintf('NNR Error: %f px/match (n = %d matches)\n', nnr_error, num_nnr_matches)
fprintf('Inliers Error: %f px/match (n = %d matches)\n', inlier_error, num_inlier_matches)
fprintf('Aligned Error: %f px/match\n', aligned_error)