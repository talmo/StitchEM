function final_tform = compose_tforms(tform1, tform2, varargin)
%COMPOSE_TFORMS Composes a number of linear transforms and returns the result as an affine2d() object.
% Usage:
%   final_tform = COMPOSE_TFORMS(tform1, ..., tformN)
%
% Notes:
%   - The input transforms can be any combination of affine2d or 3x3 double
%   matrices.
%   - These transforms are composed from left to right in the order of the
%   arguments.

tforms = [{tform1}, {tform2}, varargin];

if length(tforms) < 1
    error('Must input at least one transform.')
end

% Start at identity
final_tform = eye(3);

% Compose transforms
for i = 1:length(tforms)
    if isa(tforms{i}, 'affine2d')
        tforms{i} = tforms{i}.T;
    end
    
    final_tform = final_tform * tforms{i};
end

final_tform = affine2d(final_tform);
end

