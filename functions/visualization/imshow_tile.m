function varargout = imshow_tile(section, tile_num, varargin)
%IMSHOW_TILE Shows the specified section -> tile.

% Parameters
[tile_img, params] = parse_inputs(section, tile_num, varargin{:});

% Default spatial reference
tile_R = tform_spatial_ref(imref2d(size(tile_img)), params.tform);

% Apply the transform if image needs to be changed
if any(any(params.tform.T ~= eye(3)))
    [tile_img, tile_R] = imwarp(tile_img, params.tform);
end

% Display tile
if ~params.suppress_display
    imshow(tile_img, tile_R)
end

% Return image data
if nargout > 0
    varargout = {tile_img, tile_R};
end
end

function [tile_img, params] = parse_inputs(section, tile_num, varargin)
% Create inputParser instance
p = inputParser;
p.StructExpand = false;

p.addOptional('tform', affine2d(), @(x) isa(x, 'affine2d') || (isstruct(section) && any(validatestring(x, fieldnames(section)))));
p.addParameter('suppress_display', false);
p.addParameter('scale', 1.0);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

% Load tile
if isstruct(section) && ~isempty(section.img) && ~isempty(section.img.xy_tiles)
    tile_img = imresize(section.img.xy_tiles{tile_num}, params.scale);
elseif isstruct(section)
    tile_img = imload_tile(section.num, tile_num, params.scale);
elseif isnumeric(section)
    tile_img = imload_tile(section, tile_num, params.scale);
else
    error('Section must be a section number or a section structure.')
end

% Transform
if ischar(params.tform)
    params.tform = section.(validatestring(params.tform, fieldnames(section))){tile_num};
end

% Adjust the transform to scale
if params.scale ~= 1.0
    params.tform = compose_tforms(make_tform('scale', 1 / params.scale), params.tform, make_tform('scale', params.scale));
end
end