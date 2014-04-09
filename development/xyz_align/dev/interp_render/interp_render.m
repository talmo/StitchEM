%% Parameters
params.render_scale = 1.0;
params.tile_size = [8000 8000];
load('sec100-114_matches.mat')

%% Initialize
num_secs = length(secs);

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

%% Interpolate and render
num_secs = 1;

% Interpolation
interp_method = 'linear'; % 'nearest', 'linear', 'spline', 'pchip', 'cubic'
imwarp_interp_method = 'cubic'; % 'linear', 'nearest', 'cubic'

% Blending
blend_method = 'mean';

warning('off', 'MATLAB:nearlySingularMatrix')

for s = 1:num_secs
    fprintf('== Rendering section %d (%d/%d) | ', secs{s}.num, s, num_secs), freemem
    sec_time = tic;
    
    % Initialize final rendered section image
    section = zeros(stack_R.ImageSize, 'uint8');
    
    % Initialize count matrix if using mean blending
    if strcmp(blend_method, 'mean')
        counts = zeros(stack_R.ImageSize, 'uint8');
    end
    
    num_tiles = secs{s}.num_tiles;
    num_tiles = 3;
    for t = 1:num_tiles
        % This is the pre-calculated spatial reference of the transformed tile
        tile_R = tile_Rs{s, t};

        % Load and transform the tile image
        V = double(imwarp(imload_tile(secs{s}.num, t), render_tforms{s, t}, 'OutputView', tile_R, 'Interp', imwarp_interp_method));

        % Find the subscript limits of the tile in the section
        [secILimits, secJLimits] = stack_R.worldToSubscript(tile_R.XWorldLimits, tile_R.YWorldLimits);

        % Build grid vectors for tile subscripts
        secIqv = secILimits(1):secILimits(2); % Y
        secJqv = secJLimits(1):secJLimits(2); % X

        % Interpolate subscript grid vectors to tile image size
        tileIqv = interp1(secILimits, [1 tile_R.ImageSize(1)], secIqv);
        tileJqv = interp1(secJLimits, [1 tile_R.ImageSize(2)], secJqv);

        % Create interpolant for tile pixel values based on tile size
        F = griddedInterpolant(V, interp_method);

        % Interpolate the tile to its section coordinates
        Vq = F({tileIqv, tileJqv});

        % Blend interpolated tile image into section image
        switch blend_method
            case 'max'
                section(secIqv, secJqv) = max(section(secIqv, secJqv), uint8(Vq));
            case 'mean'
                %[secIq, secJq] = meshgrid(secIqv, secJqv);
                %[secXq, secYq] = stack_R.intrinsicToWorld(secJq, secIq);
                %mask = tile_R.contains(secXq, secYq);
                %counts(secIqv, secJqv) = counts(secIqv, secJqv) + uint8(mask);
                
                counts(secIqv, secJqv) = counts(secIqv, secJqv) + uint8(Vq ~= 0);
                
                
                section(secIqv, secJqv) = uint8((double(section(secIqv, secJqv)) + Vq) ...
                    ./ double(counts(secIqv, secJqv)));
        end
        fprintf('Rendered tile (%2d/%d) | ', t, secs{s}.num_tiles), freemem
    end
    
    % Save
    %imwrite(section, sprintf('interp_render/sec%d_max_%s.tif', secs{s}.num, interp_method))
    
    fprintf('Done rendering section %d (%d/%d) [%.2fs] | ', secs{s}.num, s, num_secs, toc(sec_time)), freemem
end

warning('on', 'MATLAB:nearlySingularMatrix')
return
%% Compare pair of tiles
 % Tiles to compare
tA = 2; tB = 3;
show_full = false;

show_seam = true;
seam_x_ratio = [0.4, 0.6]; % [left, right]
seam_y_ratio = [0, 0.3]; % [top, bottom]

% Crop section to tiles
tAB_R = merge_spatial_refs({tile_Rs{s, tA}, tile_Rs{s, tB}});
[ILimits, JLimits] = stack_R.worldToSubscript(tAB_R.XWorldLimits, tAB_R.YWorldLimits);
tAB = section(ILimits(1):ILimits(2), JLimits(1):JLimits(2));

% Calculate seam region subscripts
[seamI, seamJ] = tAB_R.worldToSubscript(...
    tAB_R.XWorldLimits(1) + tAB_R.ImageExtentInWorldX * seam_x_ratio, ...
    tAB_R.YWorldLimits(1) + tAB_R.ImageExtentInWorldY * seam_y_ratio);
seamAB = tAB(seamI(1):seamI(2), seamJ(1):seamJ(2));

% Display pair of tiles
if show_full
    figure, imshow(tAB, tAB_R)
    title(sprintf('Section %d | Tiles %d and %d | griddedInterpolant: %s | blend method: %s', secs{s}.num, tA, tB, interp_method, blend_method)), integer_axes
end

% Display seam
if show_seam
    figure, imshow(seamAB)
    title(sprintf('Section %d | Tiles %d and %d | griddedInterpolant: %s | blend method: %s', secs{s}.num, tA, tB, interp_method, blend_method)), integer_axes
end

%% Compare seam region with interp2d
interp2d_method = 'bicubic'; % 'nearest', 'bilinear', 'bicubic'
imfuse_blend_method = 'diff'; % {'falsecolor', 'blend', 'diff', 'montage'}

% Merge tiles using image processing toolbox's internal interp2d
[tAB2d, tAB2d_R] = imshow_tile_pair(imload_tile(secs{s}.num, tA), imload_tile(secs{s}.num, tB), render_tforms{s, tA}, render_tforms{s, tB}, ...
    'display_scale', 1.0, 'interp_method', interp2d_method, 'imwarp_interp_method', imwarp_interp_method, 'suppress_display', ~show_full);
if show_full
    title(sprintf('Section %d | Tiles %d and %d | interp2d -> %s', secs{s}.num, tA, tB, interp2d_method))
end

seamAB2d = tAB2d(seamI(1):seamI(2), seamJ(1):seamJ(2));

% Display pair
seam = imfuse(seamAB, seamAB2d, imfuse_blend_method);
figure, imshow(seam)
title(sprintf('Section %d | Tiles %d and %d | griddedInterpolant -> %s | interp2d -> %s', secs{s}.num, tA, tB, interp_method, interp2d_method))
