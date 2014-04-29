function varargout = estimate_tform_params(tform)
%ESTIMATE_TFORM_PARAMS Estimates the parameters used in a transform.
% Usage:
%   [scale, rotation, translation] = ESTIMATE_TFORM_PARAMS(tform)
%   ESTIMATE_TFORM_PARAMS(tform) % Outputs parameters
% Notes:
%   - tform can be a 3x3 transformation matrix or an affine2d object.

%% Parameters
if ~isa(tform, 'affine2d')
    tform = affine2d(tform);
end

%% Estimate transformation parameters
% Translation
translation = [tform.T(3) tform.T(6)];

% Transform unit vector parallel to x-axis
u = [0 1];
v = [0 0];
[x, y] = transformPointsForward(tform, u, v);
dx = x(2) - x(1);
dy = y(2) - y(1);

% Calculate angle of rotation (counterclockwise)
rotation = -atan2d(dy, dx);

% Calculate scale
scale = sqrt(dx^2 + dy^2);

if nargout < 1
    fprintf('Scale: %fx | Rotation: %f deg | Translation: [X: %12f, Y: %12f] px\n', ...
        scale, rotation, translation(1), translation(2))
else
    varargout = {scale, rotation, translation};
end
end