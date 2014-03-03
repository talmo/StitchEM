function [scale, rotation, translation] = estimate_tform_params(tform)
%ESTIMATE_TFORM_PARAMS Estimates the parameters used in a transform.

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
end