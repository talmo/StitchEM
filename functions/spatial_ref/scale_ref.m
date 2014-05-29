function R_scaled = scale_ref(R, scale)
%SCALE_REF Returns a scaled spatial reference.
% Usage:
%   R_scaled = scale_ref(R, scale)

R_scaled = imref2d(ceil(R.ImageSize .* scale), R.XWorldLimits, R.YWorldLimits);

end

