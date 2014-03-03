function varargout = imshow_tile(section_num, tile_num, varargin)
%IMSHOW_TILE Shows the specified section -> tile.

%% Parameters
% Defaults
suppress_display = false;
scale = 1.0;
tform = affine2d();

% Overwrite defaults based on variable type (sorry, really hackish)
if ~isempty(varargin)
    for i = 1:length(varargin)
        if islogical(varargin{i})
            suppress_display = varargin{i};
        elseif isnumeric(varargin{i})
            scale = varargin{i};
        elseif isa(varargin{i}, 'affine2d')
            tform = varargin{i};
        end
    end
end

%% Load and display tile
% Load tile
[tile_img, tile_img_spatial_ref] = imload_tile(section_num, tile_num);

% Combine scaling into the transform for the tile
if scale ~= 1.0
    tform_scaling = scale_tform(scale);
    tform = affine2d(tform.T * tform_scaling.T);
end

% Apply the transform if image needs to be changed
if any(any(tform.T ~= eye(3)))
    [tile_img, tile_img_spatial_ref] = imwarp(tile_img, tile_img_spatial_ref, tform);
end

% Display tile
if ~suppress_display
    imshow(tile_img, tile_img_spatial_ref)
end

% Return image data
if nargout > 0
    varargout{1} = tile_img;
    varargout{2} = tile_img_spatial_ref;
end
end

