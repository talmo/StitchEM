function [I, J] = ref2subs(RA, RB)
%REF2SUBS Returns the subscripts of RA in RB.
% Usage:
%   [I, J] = ref2subs(RA, RB)
%
% Args:
%   RA, RB: imref2d objects
%
% Notes:
%   - This function is consistent with the behavior of imref2d.
%   - The difference between this function and worldToSubscript is that we
%   this function adjusts for the limit notation BEFORE clipping to the
%   image limits.
%
% Example:
%   [I, J] = ref2subs(RA, RB)
%   B(I(1):I(2), J(1):J(2)) = A; % same size
% 
% Reference: images.spatialref.internal.SpatialDimensionManager
%
% See also: clip_lims, merge_spatial_refs, tform_spatial_ref

% World limits of A must be contained in B!
if any(~RB.contains(RA.XWorldLimits, RA.YWorldLimits))
    error('RA is not fully contained in RB.')
end

% Find the intrinsic coordinates in RB of the world limits of RA
[inX, inY] = RB.worldToIntrinsic(RA.XWorldLimits, RA.YWorldLimits);

% Convert to subscripts by rounding
I = round(inY);
J = round(inX);

% Adjust for limit vs subscript notation
I(2) = I(2) - 1; J(2) = J(2) - 1;

end

