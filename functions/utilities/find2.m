function sub = find2(X, varargin)
%FIND2 Returns the [row, col] subscripts of the output of find as an array.
% Usage:
%   sub = find2(X)
%   sub = find2(X, k)
%   sub = find2(X, k, 'first')
%   sub = find2(X, k, 'last')
%
% Note: This output of this function is equivalent to:
%   [row, col] = find(...)
%   sub = [row, col]
%
% See also: find, out2

[sub(1), sub(2)] = find(X, varargin{:});

end

