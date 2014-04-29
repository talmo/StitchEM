function final_tform = compose_tforms(varargin)
%COMPOSE_TFORMS Composes a number of linear transforms and returns the result as an affine2d() object.
% Usage:
%   final_tform = COMPOSE_TFORMS(tform1, ..., tformN)
%
% Notes:
%   - The input transforms can be any combination of affine2d or 3x3 double
%   matrices.
%   - These transforms are composed from left to right in the order of the
%   arguments.

if length(varargin) < 1
    error('Must input at least one transform.')
end

% Start at identity
final_tform = eye(3);

% Compose transforms
for i = 1:length(varargin)
    if isa(varargin{i}, 'affine2d')
        varargin{i} = varargin{i}.T;
    end
    
    final_tform = final_tform * varargin{i};
end

final_tform = affine2d(final_tform);
end

