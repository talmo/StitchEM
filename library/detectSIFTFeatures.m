function [ points, descriptors ] = detectSIFTFeatures( img )
%DETECTSIFTFEATURES Detects SIFT features in an image.
% 
% This is a MATLAB implementation of the same SIFT algorithm used in Fiji.
% 
% Copyright notice:
% The SIFT-method is protected by U.S. Patent 6,711,293: "Method and
% apparatus for identifying scale invariant features in an image and use of
% same for locating an object in an image" by the University of British
% Columbia.  That is, for commercial applications the permission of the
% author is required.

%% Parameters
descriptorSize = 4;
descriptorBins = 8;
minOctaveSize = 64;
maxOctaveSize = 1024;
steps = 3;
initialSigma = 1.6;

%% Pre-process image 

% Scale the image to the max octave size


end

