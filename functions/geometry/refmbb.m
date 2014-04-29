function varargout = refmbb(R, which_limits)
%REFMBB Finds the minimum bounding box of the limits of the spatial referencing object.
% Computes the minimum axis-aligned bounding box of the limits of the 
% spatial referencing object.
%
% Usage:
%   V = refmbb(R)
%   V = refmbb(R, which_limits)
%   [Vx, Vy] = refmbb(...)
%
% Args:
%   R is an instance of the imref2d class.
%   which_limits specifies which set of point limits to use for bounding.
%       - Defaults to 'global' or 'world'.
%       - Can also be 'intrinsic' or 'local', both of which refer to the
%       intrinsic limits of the spatial referencing object.
%
% Returns:
%   V (Mx2) or [Vx, Vy] (both Mx1), the set of vertices of the minimum AABB
%       (a rectangle/convex polynomial).
%
% See minaabb() for more info.


% Parse input
if nargin < 2
    which_limits = 'global';
else
    which_limits = validatestring(which_limits, {'global', 'world', 'intrinsic', 'local'}, mfilename, 'which_limits', 2);
end

% Get the components of the points at the limits
switch which_limits
    case {'global', 'world'}
        X = R.XWorldLimits;
        Y = R.YWorldLimits;
    case {'intrinsic', 'local'}
        X = R.XIntrinsicLimits;
        Y = R.YIntrinsicLimits;
end

% Calculates the minimum axis-aligned bounding box of the limits
[Vx, Vy] = minaabb([X(:), Y(:)]);

% Return vertices
varargout = {[Vx, Vy]};
if nargout == 2
    varargout = {Vx, Vy};
end
end
