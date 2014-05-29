function [ptA, ptB, peakVal] = find_xcorr(A, locA, B, locB)
%FIND_XCORR Finds image B in A by looking for the peak of correlation and returns a matching point pair.
% Usage:
%   [ptA, ptB] = find_xcorr(A, B)
%   [ptA, ptB] = find_xcorr(A, locA, B, locB)
%   [ptA, ptB] = find_xcorr(A, RA, B, RB)
%   [ptA, ptB, peakVal] = find_xcorr(...)
%
% Args:
%   A, B: uint8 images
%   RA, RB: imref2d objects
%   locA, locB: [x, y] world coordinates of the top-left of A and B
%
% Returns:
%   ptA = top-left of B in A
%   ptB = top-left of B == locB

if nargin == 2
    B = locA;
    locA = [0.5, 0.5];
    locB = [0.5, 0.5];
elseif nargin == 4
    if isa(locA, 'imref2d')
        locA = [locA.XWorldLimits(1), locA.YWorldLimits(1)];
    end
    if isa(locB, 'imref2d')
        locB = [locB.XWorldLimits(1), locB.YWorldLimits(1)];
    end
end

% Check if template has any variation
if std(double(B(:))) == 0
    warning('Image B has no variation, cannot perform cross-correlation.')
    ptA = [];
    ptB = [];
    peakVal = [];
    return
end

% Find the normalized cross correlation
C = normxcorr2(B, A);

% Find the peak of correlation
[peakX, peakY, peakVal] = findpeak(C, true);

% Calculate the offset of B from A
offsetX = peakX - size(B, 2);
offsetY = peakY - size(B, 1);

% Return as points in world coordinates
ptA = locA + [offsetX, offsetY];
ptB = locB;

end

