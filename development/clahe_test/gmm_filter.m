function [inliers, outliers] = gmm_filter(nnr_matches, varargin)
%GMM_FILTER Finds inliers and outliers using GMM.
% Usage:
%   [inliers, outliers] = gmm_filter(nnr_matches)

% Process parameters
[params, unmatched_params] = parse_input(varargin{:});

total_time = tic;

ptsA = nnr_matches.A;
ptsB = nnr_matches.B;

% Calculate match displacements
D = ptsB - ptsA;

% Fit two distributions to data
fit = gmdistribution.fit(D, 2, 'Replicates', 5);

% Cluster data to distributions
% http://www.mathworks.com/help/stats/gmdistribution.cluster.html
k = fit.cluster(D);

% Split data into clusters
D1 = D(k == 1, :);
D2 = D(k == 2, :);

% Choose inlier cluster
switch params.inlier_cluster
    case 'smallest_error'
        % Select the cluster with smallest error as inliers
        D1_norm = rownorm2(D1);
        D2_norm = rownorm2(D2);
        k_inliers = 1; if D1_norm > D2_norm; k_inliers = 2; end
    case 'geomedian'
        % Select the cluster that's closest to the overall geometric median
        D_geomedian = geomedian(D);
        D1_geomedian = geomedian(D1);
        D2_geomedian = geomedian(D2);
        k_inliers = 1;
        if norm(D1_geomedian - D_geomedian) > norm(D2_geomedian - D_geomedian)
            k_inliers = 2;
        end
end

% Keep just the inliers from NNR matching step
inliers.A = ptsA(k == k_inliers, :);
inliers.B = ptsB(k == k_inliers, :);

outliers.A = ptsA(k ~= k_inliers, :);
outliers.B = ptsB(k ~= k_inliers, :);

if params.verbosity > 0
    fprintf('Filtered to %d/%d matches. Error: <strong>%fpx / match</strong> [%.2fs]\n', length(inliers.A), length(ptsA), rownorm2(inliers.B - inliers.A), toc(total_time))
end

end

function [params, unmatched] = parse_input(varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Criteria for establishing cluster as inliers
inlier_clustering_methods = {'smallest_error', 'geomedian'};
p.addParameter('inlier_cluster', 'geomedian', @(x) validatestr(x, inlier_clustering_methods));

% Verbosity
p.addParameter('verbosity', 0);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;

end