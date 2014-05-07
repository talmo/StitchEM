function varargout = imshow_tile_pair(tileA, tileB, varargin)
%IMSHOW_TILE_PAIR Displays a pair of tiles after applying their transforms.
% Usage:
%   IMSHOW_TILE_PAIR(tileA, tileB)
%   IMSHOW_TILE_PAIR(tileA, tileB, tformA, tformB)
%   IMSHOW_TILE_PAIR(..., 'Name', 'Value')
%   [merge, merge_R, tileA, tileA_R, tileB, tileB_R] = IMSHOW_TILE_PAIR(...)
%
% Name-value pairs:
%   'pre_scale', 1.0
%   'display_scale', 0.1
%   'suppress_display', false
%   'blending_method', 'max', {'max', 'falsecolor', 'blend', 'diff', 'montage'}
%   'interp_method', 'bicubic', {'nearest', 'bilinear', 'bicubic'}
%   'imwarp_interp_method', 'cubic', {'linear', 'nearest', 'cubic'}

% Parse parameters
[tformA, tformB, params] = parse_inputs(varargin{:});

% Scaling
if params.pre_scale ~= params.display_scale
    % Scale tiles to display resolution
    tileA = imresize(tileA, (1 / params.pre_scale) * params.display_scale);
    tileB = imresize(tileB, (1 / params.pre_scale) * params.display_scale);
end
if params.display_scale ~= 1.0
    % Scale transforms to display resolution
    tform_prescale = make_tform('s', 1 / params.display_scale); % scale to full resolution assuming we start at display resolution
    tform_rescale = make_tform('s', params.display_scale); % scale back down to display resolution
    tformA = affine2d(tform_prescale.T * tformA.T * tform_rescale.T);
    tformB = affine2d(tform_prescale.T * tformB.T * tform_rescale.T);
end

% Get default spatial references
tileA_R = imref2d(size(tileA));
tileB_R = imref2d(size(tileB));

% Transform the tiles
if ~all(all(tformA.T == eye(3)))
    [tileA, tileA_R] = imwarp(tileA, tformA, 'Interp', params.imwarp_interp_method);
end
if ~all(all(tformB.T == eye(3)))
    [tileB, tileB_R] = imwarp(tileB, tformB, 'Interp', params.imwarp_interp_method);
end

% Merge
switch params.blending_method
    case 'max'
        % Take the maximum of the intensity at each pixel
        merge_R = merge_spatial_refs({tileA_R, tileB_R});
        tileA_padded = images.spatialref.internal.resampleImageToNewSpatialRef(tileA, tileA_R, merge_R, params.interp_method, 0);
        tileB_padded = images.spatialref.internal.resampleImageToNewSpatialRef(tileB, tileB_R, merge_R, params.interp_method, 0);
        merge = max(tileA_padded, tileB_padded);
    otherwise
        % Merge with imfuse
        [merge, merge_R] = imfuse(tileA, tileA_R, tileB, tileB_R, params.blending_method);
end

% Show merge
if ~params.suppress_display
    figure
    imshow(merge, merge_R)
    title('Merged tiles')
    integer_axes(1/params.display_scale)
end

if nargout > 0
    varargout = {merge, merge_R, tileA, tileA_R, tileB, tileB_R};
end

end

function [tformA, tformB, params] = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.StructExpand = false;

% Tile transforms
p.addOptional('tformA', affine2d());
p.addOptional('tformB', affine2d());

% Scaling
p.addParameter('pre_scale', 1.0);
p.addParameter('display_scale', 0.1);

% Just returns the merge without displaying it
p.addParameter('suppress_display', false);

% Blending method
blending_methods = {'max', 'falsecolor', 'blend', 'diff', 'montage'};
p.addParameter('blending_method', 'max', @(x) any(validatestring(x, blending_methods)));

% Interpolation methods
interp2d_methods = {'nearest', 'bilinear', 'bicubic'};  % 'bilinear' is used in imfuse
imwarp_interp_methods = {'linear', 'nearest', 'cubic'};
p.addParameter('interp_method', 'bicubic', @(x) any(validatestring(x, interp2d_methods)));
p.addParameter('imwarp_interp_method', 'cubic', @(x) any(validatestring(x, imwarp_interp_methods)));

% Validate and parse input
p.parse(varargin{:});
tformA = p.Results.tformA;
tformB = p.Results.tformB;
params = rmfield(p.Results, {'tformA', 'tformB'});

end