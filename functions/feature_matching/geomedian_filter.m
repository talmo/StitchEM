function [inliers, outliers] = geomedian_filter(matches, cutoff)
%GEOMEDIAN_FILTER Filters a set of matches by eliminating matches with a displacement distant from the geometric median.
% Usage:
%   [inliers, outliers] = geomedian_filter(matches)
%   [inliers, outliers] = geomedian_filter(matches, cutoff)
%   [inliers, outliers] = geomedian_filter(..., 'Name', Value)
%
% Args:
%   matches is a structure containing a set of matches.
%   cutoff is either a scalar number or a string ending in 'x'. When cutoff
%       is a string, the cutoff used is the product of the number in front
%       of 'x' and the average distance to the geometric median.
%       Matches above the cutoff are considered outliers.
%       Defaults to '3x'.
%
% Returns:
%   inliers and outliers are the numerical indices to the filtered matches.
%
% See also: gmdistribution, match_z, nnr_match, gmm_filter

if nargin < 2
    cutoff = '3x';
end

% Calculate match displacements
D = matches.B.global_points - matches.A.global_points;

% Calculate overall geometric median of the displacements
gm = geomedian(D);

% Calculate the distances from each point to the geometric median
[avg_dist, distances] = rownorm2(bsxadd(D, -gm));

% Convert string cutoff to double
if ischar(cutoff) && cutoff(end) == 'x'
    cutoff = str2double(cutoff(1:end-1)) * avg_dist;
end

% Make match assignments based on cutoff
inliers = find(distances <= cutoff);
outliers = find(distances > cutoff);

end

