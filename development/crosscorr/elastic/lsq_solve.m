function tform = lsq_solve(ptsA, ptsB)
%LSQ_SOLVE Solves a linear transformation using least squares and returns an affine2d object. The transform maps ptsB to ptsA.
% Usage:
%   tform = lsq_solve(ptsA, ptsB)
%
% See also: cpd_solve, sp_lsq

% Validate points
ptsA = validatepoints(ptsA);
ptsB = validatepoints(ptsB);
assert(all(size(ptsA) == size(ptsB)), 'Point sets must be of the same size.')
n = length(ptsA);

% Solve using mldivide
T = [ptsB ones(n,1)] \ [ptsA ones(n,1)];

% Replace last col since sometimes it has numbers due to numerical error
T = [T(:, 1:2) [0 0 1]'];

% Return transform as affine2d object
tform = affine2d(T);

end

