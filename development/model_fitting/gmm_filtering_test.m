%% Configuration
% Make sure secA has a 'z' alignment, secB has a 'rough_z' alignment and
% they both have Z features detected.
s = 5;
secA = secs{s - 1};
secB = secs{s};

%% Match using only NNR
nnr_matches = match_z(secA, secB, 'filter_outliers', false, 'filter_secondpass', false);
all_matches = merge_match_sets(nnr_matches);
all_displacements = all_matches.B.global_points - all_matches.A.global_points;

%% Cluster displacements by distribution
% Get all displacements
X = all_displacements;

% Fit two distributions to data
fit = gmdistribution.fit(X, 2, 'Replicates', 5);

% Cluster data to distributions
% http://www.mathworks.com/help/stats/gmdistribution.cluster.html
[k, nlogl, P, logpdf, MD] = fit.cluster(X);

% Split data into clusters
X1 = X(k == 1, :);
X2 = X(k == 2, :);

%% GMM Errors
% Calculate average distances
X_norm = rownorm2(X);
X1_norm = rownorm2(X1);
X2_norm = rownorm2(X2);

% Output
disp('<strong>GMM clustering</strong>')
disp('Errors (px / match):')
fprintf('  X: %f (n = %d)\n', X_norm, length(X))
fprintf('  X1: %f (n = %d)\n', X1_norm, length(X1))
fprintf('  X2: %f (n = %d)\n', X2_norm, length(X2))

%% Align with GMM clustered matches
% Find inlier cluster
if X1_norm < X2_norm
    k_in = 1;
else
    k_in = 2;
end
gmm_matches.A = all_matches.A(k == k_in, :);
gmm_matches.B = all_matches.B(k == k_in, :);

% Align using CPD
gmm_alignment = align_z_pair_cpd(secB, gmm_matches);

%% Plot GMM clusters
figure
plot_displacements(X), hold on
scatter(X1(:,1), X1(:,2), 'gx')
%scatter(X2(:,1), X2(:,2), 'y+')
title('GMM')

%% Plot GMM matches
figure
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'rough_z', 'g0.1')
plot_matches(gmm_matches.A, gmm_matches.B)
title('GMM')

%% Plot GMM contours
figure
scatter(X(:,1), X(:,2), 10, '.'), hold on
ezcontour(@(x,y) pdf(fit, [x y]), xlim(), ylim());

%% Plot GMM clusters colored by posterior probability
figure
scatter(X1(:, 1), X1(:, 2), 16, P(k == 1, 1), '+'), hold on
scatter(X2(:, 1), X2(:, 2), 16, P(k == 2, 1), 'o')
legend('X1','X2','Location', 'NW')
clrmap = jet(80); colormap(clrmap(9:72,:))
ylabel(colorbar,'Component 1 Posterior Probability')

%% Plot GMM membership scores
[~, P_order] = sort(P(:, 1));
plot(1:size(X,1), P(P_order,1), 'r-', 1:size(X,1), P(P_order,2), 'b-');
legend({'Cluster 1 Score', 'Cluster 2 Score'}, 'location', 'NW');
ylabel('Cluster Membership Score');
xlabel('Point Ranking');

%% Comparison: geomedfilter
% Filter by distance from geometric median
geo_threshold = '1.25x';
[inliers, outliers, X_geomed, X_dist2geomed, X_geothresh] = geomedfilter(X, 'threshold', geo_threshold);
Xin = X(inliers, :);
Xout = X(outliers, :);

% Calculate average distances
Xin_norm = rownorm2(Xin);
Xout_norm = rownorm2(Xout);

% Output
disp('<strong>geomedfilter</strong>')
fprintf('  X_geomed = [%f, %f]\n', X_geomed(1), X_geomed(2))
fprintf('  X_dist2geomed -> median = %f | sd = %f\n', median(X_dist2geomed), std(X_dist2geomed))
fprintf('  X_geothresh = %f (%s)\n', X_geothresh, geo_threshold)
disp('Errors (px / match):')
fprintf('  Xin: %f (n = %d)\n', Xin_norm, length(Xin))
fprintf('  Xout: %f (n = %d)\n', Xout_norm, length(Xout))

%% Plot geomedfilter clusters
figure
plot_displacements(X), hold on
scatter(Xin(:,1), Xin(:,2), 'gx')
%scatter(Xout(:,1), Xout(:,2), 'y+')
title('geomedfilter')

%% Align with geomedfilter matches
geomed_matches.A = all_matches.A(inliers, :);
geomed_matches.B = all_matches.B(inliers, :);

% Align using CPD
geomed_alignment = align_z_pair_cpd(secB, geomed_matches);

%% Plot geomedfilter matches
figure
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'rough_z', 'g0.1')
plot_matches(geomed_matches.A, geomed_matches.B)
title('geomedfilter')

%% Evaluate alignment errors
% Using GMM alignment
gmm_align_gmm = rownorm2(gmm_alignment.rel_tforms{1}.transformPointsForward(gmm_matches.B.global_points) - gmm_matches.A.global_points);
gmm_align_geomed = rownorm2(gmm_alignment.rel_tforms{1}.transformPointsForward(geomed_matches.B.global_points) - geomed_matches.A.global_points);

% Using geomedfilter alignment
geomed_align_geomed = rownorm2(geomed_alignment.rel_tforms{1}.transformPointsForward(geomed_matches.B.global_points) - geomed_matches.A.global_points);
geomed_align_gmm = rownorm2(geomed_alignment.rel_tforms{1}.transformPointsForward(gmm_matches.B.global_points) - gmm_matches.A.global_points);

% Save data to table
results = table();
results.gmm_align = [gmm_align_gmm; gmm_align_geomed];
results.geomed_align = [geomed_align_gmm; geomed_align_geomed];
results.Properties.RowNames = {'gmm_matches', 'geomed_matches'};
results.Properties.DimensionNames = {'matches', 'alignment'};

disp(results)