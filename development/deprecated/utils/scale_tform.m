function tform = scale_tform(scale)
%SCALE_TFORM Returns a linear scaling transformation object.

if numel(scale) == 1
    % Uniform scaling
    sx = scale;
    sy = scale;
elseif numel(scale) == 2
    % Non-uniform scaling
    sx = scale(1);
    sy = scale(2);
else
    error('Scaling must have only 1 or 2 components.')
end

tform = affine2d([sx 0 0; 0 sy 0; 0 0 1]);
end

