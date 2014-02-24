function [theta, tx, ty, scale] = analyze_tform(tform)

% Translation
tx = tform.T(3);
ty = tform.T(6);

% Transform unit vector parallel to x-axis
u = [0 1];
v = [0 0];
[x, y] = transformPointsForward(tform, u, v);
dx = x(2) - x(1);
dy = y(2) - y(1);

% Calculate rotation
theta = atan2d(dy, dx);
% Note about sign of angle:
% This is the angle of clockwise rotation!
% The theta above corresponds to the transformation matrix:
%    [cosd(theta)  -sind(theta)  0; 
%     sind(theta)   cosd(theta)  0;
%     0             0            1]
% 


% Calculate scale
scale = 1 / sqrt(dx^2 + dy^2);

% Alternative:
%u = [1 0];
%v = tform.transformPointsForward(u);
%v(1) = v(1) - tx;
%v(2) = v(2) - ty;
%theta = acosd((dot(u, v)) / (norm(u) * norm(v)));

end

