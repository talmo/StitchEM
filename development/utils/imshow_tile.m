function varargout = imshow_tile(section_num, tile_num, varargin)
%IMSHOW_TILE Shows the specified section -> tile.

%% Parameters
% Defaults
suppress_display = false;
scale = 1.0;
data_path = '/data/home/talmo/EMdata/W002';
tile_filename_pattern = 'S2-W002_Sec%d_Montage';
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
% Find path to tile image
section_path = fullfile(data_path, sprintf(tile_filename_pattern, section_num));
tile_image_paths = find_tile_images(section_path, true);

% Load tile image from file
tile_img = imread(tile_image_paths{tile_num});
tile_img_spatial_ref = imref2d(size(tile_img));

% Combine scaling into the transform for the tile
if scale ~= 1.0
    tform_scaling = scale_tform(scale);
    tform = affine2d(tform.T * tform_scaling.T);
end

% Apply the transform if image needs to be changed
if any(any(tform.T ~= eye(3)))
    disp('asdsad')
    [tile_img, tile_img_spatial_ref] = imwarp(tile_img, tile_img_spatial_ref, tform);
end

% Display tile
if ~suppress_display
    imshow(tile_img, tile_img_spatial_ref)
end

% Return image data
if nargout > 0
    varargout{1} = tile_img;
end
end

