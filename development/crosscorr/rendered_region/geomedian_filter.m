function [inliersA, inliersB, outliersA, outliersB] = geomedian_filter(ptsA, ptsB)
%GEOMEDIAN_FILTER
%   [inliersA, inliersB, outliersA, outliersB] = geomedian_filter(ptsA, ptsB)

D = ptsB - ptsA;

gm = geomedian(D);

[mean_norm, norms] = rownorm2(bsxadd(D , -gm));

cutoff = 1.5 * mean_norm;

idx = norms <= cutoff;

inliersA = ptsA(idx, :);
inliersB = ptsB(idx, :);

outliersA = ptsA(~idx, :);
outliersB = ptsB(~idx, :);
end

