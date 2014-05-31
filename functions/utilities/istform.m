function [TF, has_forward] = istform(A)
%ISTFORM Returns true if A is a geometric transformation.
% Usage:
%   TF = istform(A)
%   [TF, has_forward] = istform(A)
%
% Returns:
%   TF is true if A is a subclass of images.geotrans.internal.GeometricTransformation.
%   has_forward is true if A has a transformPointsForward method
%   (not a required method of GeometricTransformation).
%
% See also: affine2d

TF = isa(A, 'images.geotrans.internal.GeometricTransformation');
has_forward = TF && ismethod(A,'transformPointsForward');
end

