function tform = make_tform(type, varargin)
%MAKE_TFORM Creates a linear transformation matrix.
% Usage:
%   tform = MAKE_TFORM('translate', tx, ty)
%   tform = MAKE_TFORM('scale', sx, sy)
%   tform = MAKE_TFORM('rotate', theta)
%   tform = MAKE_TFORM('shear', shx, shy)
% Notes:
%   - tform is returned as an affine2d() object.
%   - The rotation angle is for a counterclockwise rotation.
%   - Parameters with x and y components can be inputed as a single
%   2-element vector or a scalar.

if isempty(varargin)
    error('Must specify transformation parameters.')
end

if length(varargin) == 1
    if length(varargin{1}) == 1
        arg1 = varargin{1};
        arg2 = varargin{1};
    elseif length(varargin{1}) == 2
        arg1 = varargin{1}(1);
        arg2 = varargin{1}(2);
    else
        error('Wrong number of parameters specified.')
    end
elseif length(varargin) == 2
    arg1 = varargin{1};
    arg2 = varargin{2};
else
    error('Wrong number of parameters specified.')
end

switch type
    case {'t', 'translate', 'translation'}
        tx = arg1;
        ty = arg2;
        tform = affine2d([1 0 0; 0 1 0; tx ty 1]);
        
    case {'s', 'scale', 'scaling'}
        sx = arg1;
        sy = arg2;
        tform = affine2d([sx 0 0; 0 sy 0; 0 0 1]);
        
    case {'r', 'rotate', 'rotation'}
        theta = arg1;
        tform = affine2d([cosd(theta) -sind(theta) 0; sind(theta) cosd(theta) 0; 0 0 1]);
        
    case {'sh', 'shear', 'shearing'}
        shx = arg1;
        shy = arg2;
        tform = affine2d([1 shy 0; shx 1 0; 0 0 1]);
        
    otherwise
        error('Transform type must be translate, scale, rotation or shearing.')
end
end
