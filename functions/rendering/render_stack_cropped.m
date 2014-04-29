function render_stack_cropped(secs, varargin)
%RENDER_STACK_CROPPED Renders a cropped region of the sections after applying their alignment transforms.

%% Parse parameters
params = parse_inputs(varargin{:});

num_secs = length(secs);
total_render_time = tic;
if params.verbosity > 0
    fprintf('== Rendering %d sections at %sx scale.\n', num_secs, num2str(params.render_scale))
end

%% Calculate stack spatial reference
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

tic;
% Calculate final spatial referencing object for stack
tile_Rs = cell(size(render_tforms));
tile_size = round(params.tile_size * params.render_scale);
% for s = 1:num_secs
%     for t = 1:secs{s}.num_tiles
%         %tile_size = round(params.tile_size * params.render_scale);
%         tile_Rs{s, t} = tform_spatial_ref(imref2d(tile_size), render_tforms{s, t});
%     end
% end

parfor i = 1:numel(tile_Rs)
    tile_Rs{i} = tform_spatial_ref(imref2d(tile_size), render_tforms{i});
end
stack_R = merge_spatial_refs(tile_Rs(:));
toc
tic
% Adjust the tile spatial references to the final stack R
for s = 1:num_secs
    for t = 1:secs{s}.num_tiles
        % Get section subscripts
        [secILimits, secJLimits] = stack_R.worldToSubscript(tile_Rs{s, t}.XWorldLimits, tile_Rs{s, t}.YWorldLimits);

        % Adjust tile to stack spatial reference
        tile_R = imref2d([diff(secILimits) + 1, diff(secJLimits) + 1], stack_R.PixelExtentInWorldX, stack_R.PixelExtentInWorldY);
        tile_R.XWorldLimits = tile_Rs{s, t}.XWorldLimits;
        tile_R.YWorldLimits = tile_Rs{s, t}.YWorldLimits;

        % Save adjusted spatial reference
        tile_Rs{s, t} = tile_R;
    end
end
toc
fprintf('Done processing transforms and spatial references.\n')

%% Render section regions
%       x     y
pos = [25000 25000];
sz = 500;
pad = 25 * [-1 +1];


% Define spatial ref of cropped region
% Define spatial ref of cropped region + padding
% Get AABB of cropped region + padding -> P
% For each section:
    % For each tile:
        % Apply inverse transform of tile to P -> P'
        % Find intersection between AABB of tile and P' -> I
        % If I is not empty:
            % Get AABB of I -> Q
            % (?)Convert Q to subscripts?
            % Load region of tile image defined by Q
            % Define spatial ref of Q relative to the tile's default R
            % (?) Define output spatial ref (adjust for pixel extent?)
            % Transform Q region of image
            % Crop to non-padded
            % Blend with section blank region
            % Save
            
            
% Inverse transform of the AABB 

% Subscripts on the rendered sections
croppedI = [pos(2) pos(2) + sz - 1]; % y
croppedJ = [pos(1) pos(1) + sz - 1]; % x

% Pixels on the rendered sections
croppedXIntrinsicLimits = croppedJ;
croppedYIntrinsicLimits = croppedI;

% World coordinates based on stack of cropped region
[croppedXWorldLimits, croppedYWorldLimits] = stack_R.intrinsicToWorld(croppedXIntrinsicLimits, croppedYIntrinsicLimits);

% Cropped region spatial referencing object
cropped_R = imref2d([sz, sz], stack_R.PixelExtentInWorldX, stack_R.PixelExtentInWorldY);
cropped_R.XWorldLimits = croppedXWorldLimits; 
cropped_R.YWorldLimits = croppedYWorldLimits;

% Calculate the limits of the padded cropped region
[padded_croppedXWorldLimits, padded_croppedYWorldLimits] = stack_R.intrinsicToWorld(croppedXIntrinsicLimits + pad, croppedYIntrinsicLimits + pad);

% Calculate a spatial referencing object for the output
padded_cropped_R = imref2d(cropped_R.ImageSize + [diff(pad) diff(pad)], stack_R.PixelExtentInWorldX, stack_R.PixelExtentInWorldY);
padded_cropped_R.XWorldLimits = padded_croppedXWorldLimits;
padded_cropped_R.YWorldLimits = padded_croppedYWorldLimits;

% Pre-initialize stack container
cropped_renders = zeros([cropped_R.ImageSize, num_secs], 'uint8');

% Turn off warnings about nearly singular matrix
pctRunOnAll warning('off', 'MATLAB:nearlySingularMatrix')
warning('off', 'MATLAB:nearlySingularMatrix')

% Loop through sections
for s = 1:num_secs % this can be parfor
    sec_time = tic;
    sec_cropped_render = zeros(cropped_R.ImageSize, 'uint8');
    
    for t = 1:secs{s}.num_tiles
        if any(tile_Rs{s, t}.contains(cropped_R.XWorldLimits', cropped_R.YWorldLimits'))
            tile_size = round(params.tile_size * params.render_scale);
            original_tile_R = imref2d([tile_size, tile_size]);
            tform = render_tforms{s, t};
            
            % Apply the inverse transform on the cropped region bounds with padding
            [original_tile_croppedXWorldLimits, original_tile_croppedYWorldLimits] = tform.transformPointsInverse(padded_croppedXWorldLimits, padded_croppedYWorldLimits);
            
            % TODO: Clip these limits to the actual limits of the tile
            % (i.e., account for calculated limits outside of [0, 8000])
            % This happens with s = 50, t = 10
            
            % Visualize overlap with unwarped tile:
            O = minaabb([original_tile_R.XWorldLimits'; original_tile_R.YWorldLimits']); % box around original tile
            V = minaabb([padded_croppedXWorldLimits', padded_croppedYWorldLimits']); % box around padded region
            P = tform.transformPointsInverse(V); % transform padded region back to original tile's coordinate system
            figure, patch(O(:,1), O(:,2), 'b'), patch(P(:,1), P(:,2), 'c'), integer_axes
            
            % Get the subscripts of the image data to transform
            [original_tile_croppedI, original_tile_croppedJ] = original_tile_R.worldToSubscript(original_tile_croppedXWorldLimits, original_tile_croppedYWorldLimits);
            
            % Create a spatial referencing object for the original cropped region
            original_tile_cropped_R = imref2d([diff(original_tile_croppedI) + 1, diff(original_tile_croppedJ) + 1], original_tile_croppedXWorldLimits, original_tile_croppedYWorldLimits);
            
            % Load the tile
            original_tile_img = imload_tile(secs{s}.num, t);
            
            % Crop it
            original_tile_cropped_img = original_tile_img(original_tile_croppedI(1):original_tile_croppedI(2), original_tile_croppedJ(1):original_tile_croppedJ(2));
            
            % Apply the transform
            [warped_tile_cropped_img, warped_tile_cropped_R] = imwarp(original_tile_cropped_img, original_tile_cropped_R, tform, 'OutputView', padded_cropped_R);
            
            % Get the subscripts of the intended cropped region
            [tile_croppedI, tile_croppedJ] = warped_tile_cropped_R.worldToSubscript(cropped_R.XWorldLimits, cropped_R.YWorldLimits);
            
            % Crop out the intended region
            tile_cropped = warped_tile_cropped_img(tile_croppedI(1):tile_croppedI(2), tile_croppedJ(1):tile_croppedJ(2));
            
            % Blend it with section render
            sec_cropped_render = max(sec_cropped_render, tile_cropped);
        end
    end
    
    cropped_renders(:, :, s) = sec_cropped_render;
    fprintf('Done section %d/%d. [%.2fs]\n', s, num_secs, toc(sec_time))
end

% Turn warnings back on
pctRunOnAll warning('on', 'MATLAB:nearlySingularMatrix')
warning('on', 'MATLAB:nearlySingularMatrix')

% Save to file
tif_stack_path = sprintf('sec%d-%d_[%d,%d].tif', secs{1}.num, secs{end}.num, pos(1), pos(2));
for s = 1:num_secs
    imwrite(cropped_renders(:, :, s), tif_stack_path, 'WriteMode', 'append')
end

if params.verbosity > 0
    fprintf('Done rendering %d sections. [%.2fs]\n', length(secs), toc(total_render_time))
end

end

function params = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.StructExpand = false;

% Scaling
p.addParameter('render_scale', 1.0);
p.addParameter('tile_size', [8000 8000]);

% Saving
p.addParameter('path', 'renders');

% Verbosity
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

% Create save path folder if needed
if ~exist(params.path, 'dir')
        mkdir(params.path)
end

end