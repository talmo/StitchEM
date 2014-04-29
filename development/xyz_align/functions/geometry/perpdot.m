function c = perpdot(A, B)
%PERPDOT Returns the perp dot product of A and B.
% Formula: c = dot(perp(A), B)
%
% Notes:
%   - This is the same as cross2(A, B).
%   - When c = 0, A and B are parallel or coincident.
%
% Reference:
%   http://geomalgorithms.com/vector_products.html
%   http://mathworld.wolfram.com/PerpDotProduct.html

c = dot(perp(A), B);

end

