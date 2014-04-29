function c = cross2(A, B)
%CROSS2 Computes the "cross-product" of two vectors in 2-D.
%
% This is equivalent to the magnitude of the 3-D cross product of the
% vectors [Ax Ay 0] and [Bx By 0].
%
% Notes:
%   - This is the same thing as perpdot(A, B).
%   - When c = 0, A and B are parallel or coincident.
%
% Reference:
%   http://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect/565282#565282
%
% See also: perpdot, perp

c = A(1) * B(2) - A(2) * B(1);

end

