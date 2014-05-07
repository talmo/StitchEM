function [XLims_clipped, YLims_clipped] = clip_lims(XLims, YLims, sz)
%CLIP_LIMS Clips a set of X and Y limits to the intrinsic coordinates of an image of the specified size.
% Usage:
%   [XLims_clipped, YLims_clipped] = clip_lims(XLims, YLims, sz)
%
% See also: sz2lims, sz2bb

% Get intrinsic bounds of the image
[img_XLims, img_YLims] = sz2lims(sz);

% Clip
XLims_clipped = [max(XLims(1), img_XLims(1)), min(XLims(2), img_XLims(2))];
YLims_clipped = [max(YLims(1), img_YLims(1)), min(YLims(2), img_YLims(2))];

end

