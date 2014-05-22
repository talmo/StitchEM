function [XLims, YLims] = sz2lims(sz)
%SZ2LIMS Returns the intrinsic limits of an image of the given size.
% Usage:
%   [XLims, YLims] = sz2lims(sz)
%
% Note: These limits are the same as the intrinsic limits in imref2d(sz).
% 
% See also: sz2bb, clip_lims

XLims = [0.5, sz(2) + 0.5];
YLims = [0.5, sz(1) + 0.5];

end

