function varargout = imshow_section(sec, varargin)
%IMSHOW_SECTION Merges tiles that are registered to the global coordinate grid by the inputted tforms.
% Usage:
%   IMSHOW_SECTION(sec_num)
%   IMSHOW_SECTION(sec_struct)
%   IMSHOW_SECTION('tile_imgs', tile_imgs)
%   IMSHOW_SECTION('tile_imgs', tile_imgs, 'tforms', tforms)
%   IMSHOW_SECTION(..., 'Name', Value)
%   [merge, merge_R] = IMSHOW_SECTION(...)
%
% Name-Value pairs:
%   'pre_scale', 1.0
%   'display_scale', 0.025
%   'suppress_display', false
%   'method', 'max'
%
% Notes:
%   - You can pass a sec_struct without any images stored to load the
%   images from disk.
%   - The tforms parameter can take a cell array of transforms, or if a
%   sec_struct was passed in, 'rough' or 'fine' can be used to specify
%   which set of transforms to use. Rough transforms are used by default.

total_time = tic;

% Parse parameters
[tile_imgs, tforms, sec_num, params] = parse_inputs(sec, varargin{:});
num_tiles = length(tile_imgs);

if params.verbosity > 0; fprintf('Merging section %d at %sx scale.\n', sec_num, num2str(params.display_scale)); end

% Adjust transforms to display scale
tform_prescale = scale_tform(1 / params.display_scale); % scale to full resolution assuming we start at display scale
tform_rescale = scale_tform(params.display_scale); % scale back down to display scale
for tile_num = 1:num_tiles
    tforms{tile_num} = affine2d(tform_prescale.T * tforms{tile_num}.T * tform_rescale.T);
end

% Calculate output spatial references
tile_Rs = cell(num_tiles, 1);
for tile_num = 1:num_tiles
    tile_size = round(size(tile_imgs{tile_num}) * (1 / params.pre_scale) * params.display_scale);
    tile_Rs{tile_num} = tform_spatial_ref(imref2d(tile_size), tforms{tile_num});
end
merge_R = merge_spatial_refs(tile_Rs);

% Turn off warnings about bad scaling
pctRunOnAll warning('off', 'MATLAB:nearlySingularMatrix')

% Scale, transform and pad images in parallel
final_tiles = cell(num_tiles, 1);
pre_scale = params.pre_scale;
display_scale = params.display_scale;
parfor tile_num = 1:num_tiles
    tic;
    tile = tile_imgs{tile_num};
    
    % Scale tile to display scale
    if pre_scale ~= display_scale
        tile = imresize(tile, (1 / pre_scale) * display_scale);
    end
    
    % Transform
    [tile, tile_R] = imwarp(tile, tforms{tile_num}, 'Interp', 'cubic');
    
    % Pad
    tile = images.spatialref.internal.resampleImageToNewSpatialRef(tile, tile_R, merge_R, 'bicubic', 0);
    
    % Save
    final_tiles{tile_num} = tile;
end

% Merge stack of tiles
merge = max(cat(3, final_tiles{:}), [], 3);

fprintf('Done merging section. [%.2fs]\n', toc(total_time))

% Turn warnings about bad scaling back on
pctRunOnAll warning('on', 'MATLAB:nearlySingularMatrix')

% Display the image
if ~params.suppress_display
    % Show image without warning about scale
    warning('off', 'images:initSize:adjustingMag')
    imshow(merge, merge_R)
    
    % Adjust figure
    if sec_num ~= 0
        sec_str = [' ' num2str(sec_num)];
    else
        sec_str = '';
    end
    title(sprintf('Merged section%s (%d tiles)', sec_str, length(tile_imgs)))
    integer_axes(1/params.display_scale)
    warning('on', 'images:initSize:adjustingMag')
end

% Return the merge
if nargout > 0
    varargout = {merge, merge_R};
end
end

function [tile_imgs, tforms, sec_num, params] = parse_inputs(sec_arg, varargin)
% Create inputParser instance
p = inputParser;
p.StructExpand = false;

% Section structure or number
p.addOptional('sec', 0);

% Transforms to apply to tiles, otherwise they will be displayed in a grid
p.addOptional('tforms', {});

% Optionally use pre-loaded/scaled tile images
p.addParameter('tile_imgs', {});
p.addParameter('pre_scale', 1.0);

% Scaling
p.addParameter('display_scale', 0.025);

% Just returns the merge without displaying it
p.addParameter('suppress_display', false);

% Image blending method
p.addParameter('method', 'max');

% Debugging/development
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(sec_arg, varargin{:});
sec = p.Results.sec;
tile_imgs = p.Results.tile_imgs;
tforms = p.Results.tforms;
params = rmfield(p.Results, {'sec', 'tile_imgs', 'tforms'});

% Section structure was passed in (structure created in load_sec())
if isstruct(sec)
    sec_num = sec.num;
    if params.verbosity > 1; fprintf('Using pre-loaded structure for section %d.\n', sec_num); end
    
    % Transforms
    if isempty(tforms) || (ischar(tforms) && strcmp(tforms, 'rough'))
        tforms = sec.rough_tforms;
        if params.verbosity > 1; disp('Using rough alignments to display tiles.'); end
    elseif ischar(tforms) && strcmp(tforms, 'fine')
        tforms = sec.fine_tforms;
        if params.verbosity > 1; disp('Using fine alignments to display tiles.'); end
    end
    
    % Tile images
    if ~isempty(sec.img) && ~isempty(sec.img.rough_tiles) && sec.tile_rough_scale >= params.display_scale
        tile_imgs = sec.img.rough_tiles;
        params.pre_scale = sec.tile_rough_scale;
        if params.verbosity > 1; fprintf('Using rough tiles to render (%sx).\n', num2str(sec.tile_rough_scale)); end
        
    elseif ~isempty(sec.img) && ~isempty(sec.img.z_tiles) && sec.tile_z_scale >= params.display_scale
        tile_imgs = sec.img.z_tiles;
        params.pre_scale = sec.tile_z_scale;
        if params.verbosity > 1; fprintf('Using Z tiles to render (%sx).\n', num2str(sec.tile_z_scale)); end
        
    elseif ~isempty(sec.img) && ~isempty(sec.img.xy_tiles)
        tile_imgs = sec.img.xy_tiles;
        params.pre_scale = sec.tile_xy_scale;
        if params.verbosity > 1; fprintf('Using XY tiles to render (%sx).\n', num2str(sec.tile_xy_scale)); end
    end
else
    sec_num = sec;
end

% Load (and scale) tiles if the images were not passed in
if isempty(tile_imgs)
    if sec_num == 0
        error('You must either specify a section number or input an array of tile images.')
    end
    if params.verbosity > 0; load_tiles_time = tic; fprintf('Loading tile images for section %d...', sec_num); end
    
    % Load
    tile_imgs = imload_section_tiles(sec_num, params.display_scale);
    
    % Adjust the pre_scale parameter
    params.pre_scale = params.display_scale;
    if params.verbosity > 0; fprintf(' Done. [%.2fs]\n', toc(load_tiles_time)); end
end

% Initialize transform container if it's empty
if isempty(tforms)
    tforms = cell(length(tile_imgs), 1);
    if params.verbosity > 1; disp('Using grid alignments to display tiles.'); end
end

% Fill in any missing transforms by aligning to grid
if any(cellfun('isempty', tforms))
    tforms = estimate_tile_grid_alignments(tforms);
end
end