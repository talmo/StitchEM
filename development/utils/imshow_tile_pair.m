function varargout = imshow_tile_pair(tileA, tileB, tformA, tformB, varargin)
%IMSHOW_TILE_PAIR Displays a pair of tiles after applying their transforms.

% Parse parameters
params = parse_inputs(varargin{:});

% Scaling
if params.pre_scale ~= params.display_scale
    % Scale transforms to display resolution
    tform_prescale = scale_tform(1 / params.display_scale); % scale to full resolution assuming we start at display resolution
    tform_rescale = scale_tform(params.display_scale); % scale back down to display resolution
    tformA = affine2d(tform_prescale.T * tformA.T * tform_rescale.T);
    tformB = affine2d(tform_prescale.T * tformB.T * tform_rescale.T);

    % Scale tiles to display resolution
    tileA = imresize(tileA, (1 / params.pre_scale) * params.display_scale);
    tileB = imresize(tileB, (1 / params.pre_scale) * params.display_scale);
end

% Transform the tiles
[tileA_warped, tileA_warped_R] = imwarp(tileA, tformA, 'Interp', 'cubic');
[tileB_warped, tileB_warped_R] = imwarp(tileB, tformB, 'Interp', 'cubic');

% Merge
switch params.blending_method
    case 'max'
        % Take the maximum of the intensity at each pixel
        merge_R = merge_spatial_refs({tileA_warped_R, tileB_warped_R});
        tileA_padded = images.spatialref.internal.resampleImageToNewSpatialRef(tileA_warped, tileA_warped_R, merge_R, 'bicubic', 0);
        tileB_padded = images.spatialref.internal.resampleImageToNewSpatialRef(tileB_warped, tileB_warped_R, merge_R, 'bicubic', 0);
        merge = max(tileA_padded, tileB_padded);
    otherwise
        % Merge with imfuse
        [merge, merge_R] = imfuse(tileA_warped, tileA_warped_R, tileB_warped, tileB_warped_R, params.blending_method);
end

% Show merge
if ~params.suppress_display
    figure
    imshow(merge, merge_R)
    title('Merged tiles')
    integer_axes(1/params.display_scale)
end

if nargout > 0
    varargout = {merge, merge_R, tileA_warped, tileA_warped_R, tileB_warped, tileB_warped_R};
end

end

function params = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.StructExpand = false;

% Scaling
p.addParameter('pre_scale', 1.0);
p.addParameter('display_scale', 0.1);

% Just returns the merge without displaying it
p.addParameter('suppress_display', false);

% Blending method
p.addParameter('blending_method', 'falsecolor'); % or 'max'

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

end