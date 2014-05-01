function [passed, exception] = validateattr(A, classes, attributes, varargin)
%VALIDATEATTR Returns true if validateattributes passes successfully.
%
% Usage:
%   passed = validateattr(A, classes, attributes, ...)
%   [passed, exception] = validateattr(...)
%
% See also: validateattributes

passed = true;
exception = [];
try
    validateattributes(A, classes, attributes, varargin{:});
catch exception
    passed = false;
end
end

