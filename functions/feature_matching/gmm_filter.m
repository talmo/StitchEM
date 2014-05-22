function [inliers, outliers] = gmm_filter(matches, varargin)
%GMM_FILTER Filters a set of matches by clustering their displacements with Gaussian Mixture Models.
% Usage:
%   [inliers, outliers] = gmm_filter(matches)
%   [inliers, outliers] = gmm_filter(matches, 'Name',Value)
%
% Parameters:
%   'Replicates', 5: The number of times to repeat the EM algorithm to fit
%       the Gaussian mixtures.
%       Increasing this number increases robustness in cases where it is
%       difficult to find a good fit, but at the cost of performance.
%       More replicates also ensure consistent results across runs.
%
%   'inlier_cluster', 'geomedian': The method for determining which cluster
%       contains inliers.
%           'geomedian': Chooses the cluster with the geometric median
%           that is closest to the overall geometric median.
%           'smallest_error': Chooses the cluster with the smallest average
%           error per match.
%       Note: In cases of large misalignment, the cluster with the smallest
%       error may not be the inliers.
%
%   'warning', 'off': The behavior when the GMM algorithm throws warnings
%       due to failure to converge or ill-conditioned covariance matrix.
%       This usually happens when there are too few matches to fit a good
%       set of distributions, or when there are 100% inliers or outliers
%       (i.e., all the displacements come from the same distribution).
%       Can be: 'off', 'on', or 'error'.
%
% Returns:
%   inliers and outliers are the numerical indices to the matches in each
%       of the clusters.
%
% See also: gmdistribution, match_z, nnr_match, geomedian_filter

% Process parameters
params = parse_input(varargin{:});

% Calculate match displacements
D = matches.B.global_points - matches.A.global_points;
        
% Change what we do if we fail to converge or terminate early
warning(params.warning, 'stats:gmdistribution:FailedToConvergeReps')
warning(params.warning, 'stats:gmdistribution:IllCondCov');

% Fit two distributions to data
fit = gmdistribution.fit(D, 2, 'Replicates', params.Replicates);

% Cluster data to distributions
% http://www.mathworks.com/help/stats/gmdistribution.cluster.html
k = fit.cluster(D);

% Return messages to warning level
warning('on', 'stats:gmdistribution:FailedToConvergeReps')
warning('on', 'stats:gmdistribution:IllCondCov');

% Split data into clusters
D1 = D(k == 1, :);
D2 = D(k == 2, :);

% Choose inlier cluster
switch params.inlier_cluster
    case 'smallest_error'
        % Select the cluster with the smallest error
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

% Return clustered indices
inliers = find(k == k_inliers);
outliers = find(k ~= k_inliers);

end

function params = parse_input(varargin)

% Create inputParser instance
p = inputParser;

% GMM Replicates
p.addParameter('Replicates', 5);

% Criteria for establishing cluster as inliers
%   smallest_error: choose the cluster with the smallest error as the inliers
%   geomedian: choose the cluster with the smallest average distance to the
%   geometric median as the inliers
inlier_clustering_methods = {'smallest_error', 'geomedian'};
p.addParameter('inlier_cluster', 'geomedian', @(x) validatestr(x, inlier_clustering_methods));

% What to do with warnings
p.addParameters('warning', 'off', @(x) validatestr(x, {'on', 'off', 'error'}));

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

end