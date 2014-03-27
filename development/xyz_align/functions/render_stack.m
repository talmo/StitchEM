function render_stack(secs, varargin)
%RENDER_STACK Renders sections after applying their alignment transforms.

% Parse parameters
params = parse_inputs(varargin{:});

num_secs = length(secs);
total_render_time = tic;
if params.verbosity > 0
    fprintf('== Rendering %d sections at %sx scale.\n', num_secs, num2str(params.render_scale))
end

% Adjust alignment transforms to render scale
render_tforms = cell(num_secs, max(cellfun(@(sec) sec.num_tiles, secs)));
for s = 1:num_secs
    if params.render_scale ~= 1.0
        tform_prescale = scale_tform(1 / params.render_scale); % scale to full resolution assuming we start at render scale
        tform_rescale = scale_tform(params.render_scale); % scale back to render scale after applying tform at full scale
        for t = 1:secs{s}.num_tiles
            render_tforms{s, t} = affine2d(tform_prescale.T * secs{s}.fine_tforms{t}.T * tform_rescale.T);
        end
    else
        % No adjustment needed if we're rendering at full resolution
        render_tforms(s, :) = secs{s}.fine_tforms;
    end
end

% Calculate final spatial referencing object for stack
tile_Rs = cell(num_secs, max(cellfun(@(sec) sec.num_tiles, secs)));
for s = 1:num_secs
    for t = 1:secs{s}.num_tiles
        tile_size = round(params.tile_size * params.render_scale);
        tile_Rs{s, t} = tform_spatial_ref(imref2d(tile_size), render_tforms{s, t});
    end
end
stack_R = merge_spatial_refs(tile_Rs(:));

% Render sections
for s = 1:num_secs
    sec_render_time = tic;
    
    % Load images
    switch params.tile_images
        case 'load'
            tile_imgs = imload_section_tiles(secs{s}.num, params.render_scale);
            pre_scale = params.render_scale;
        case 'xy'
            tile_imgs = secs{s}.img.xy_tiles;
            pre_scale = secs{s}.tile_xy_scale;
        case 'z'
            tile_imgs = secs{s}.img.z_tiles;
            pre_scale = secs{s}.tile_z_scale;
        case 'rough'
            tile_imgs = secs{s}.img.rough_tiles;
            pre_scale = secs{s}.tile_rough_scale;
    end
    
    % Render
    sec_img = render_section(tile_imgs, render_tforms(s, :), stack_R, pre_scale, params.render_scale);
    
    % Save
    imwrite(sec_img, fullfile(params.path, sprintf('sec%d_%sx.tif', secs{s}.num, num2str(params.render_scale))));
    
    if params.verbosity > 0
        fprintf('Rendered section %d (%d/%d). [%.2fs]\n', secs{s}.num, s, num_secs, toc(sec_render_time))
    end
end

if params.verbosity > 0
    fprintf('Done rendering %d sections. [%.2fs]\n', length(secs), toc(total_render_time))
end

end

function sec_img = render_section(tile_imgs, render_tforms, stack_R, pre_scale, render_scale)

num_tiles = length(tile_imgs);

% Turn off warnings about bad scaling
pctRunOnAll warning('off', 'MATLAB:nearlySingularMatrix')

% Scale, transform and pad images in parallel
final_tiles = cell(num_tiles, 1);
for tile_num = 1:num_tiles
    tile = tile_imgs{tile_num};
    
    % Scale tile to render scale
    if pre_scale ~= render_scale
        tile = imresize(tile, (1 / pre_scale) * render_scale);
    end
    
    % Transform
    [tile, tile_R] = imwarp(tile, render_tforms{tile_num}, 'Interp', 'cubic');
    
    % Pad
    tile = images.spatialref.internal.resampleImageToNewSpatialRef(tile, tile_R, stack_R, 'bicubic', 0);
    
    % Save
    final_tiles{tile_num} = tile;
end

% Merge stack of tiles
sec_img = max(cat(3, final_tiles{:}), [], 3);

% Turn warnings about bad scaling back on
pctRunOnAll warning('on', 'MATLAB:nearlySingularMatrix')

end

function params = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.StructExpand = false;

% Images
p.addParameter('tile_images', 'load'); % or 'xy' or 'rough' or 'z'

% Scaling
p.addParameter('render_scale', 0.025);
p.addParameter('tile_size', [8000 8000]);

% Saving
p.addParameter('path', 'renders')

% Verbosity
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

end