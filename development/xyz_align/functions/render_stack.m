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
pctRunOnAll warning('off', 'MATLAB:nearlySingularMatrix')
warning('off', 'MATLAB:nearlySingularMatrix')
for s = 1:num_secs
    sec_render_time = tic;
    if params.verbosity > 1
        fprintf('== Rendering section %d (%d/%d) | ', secs{s}.num, s, num_secs)
        freemem
    end

    % Load tiles
    tiles = imload_section_tiles(secs{s}.num, params.render_scale);

    % Blend tiles into section image
    sec_img = zeros(stack_R.ImageSize, 'uint8');
    for t = 1:secs{s}.num_tiles
        tile_render_time = tic;
        
        % Get section subscripts
        [secILimits, secJLimits] = stack_R.worldToSubscript(tile_Rs{s, t}.XWorldLimits, tile_Rs{s, t}.YWorldLimits);
        
        % Adjust tile to stack spatial reference
        tile_R = imref2d([diff(secILimits) + 1, diff(secJLimits) + 1], stack_R.PixelExtentInWorldX, stack_R.PixelExtentInWorldY);
        
        % Load and transform tile
        tile = imwarp(tiles{t}, render_tforms{s, t}, 'OutputView', tile_R);
        
        % Merge tile into section image
        sec_img(secILimits(1):secILimits(2), secJLimits(1):secJLimits(2)) = ...
            max(sec_img(secILimits(1):secILimits(2), secJLimits(1):secJLimits(2)), tile);
        
        if params.verbosity > 1
            fprintf('Transformed and merged tile %2d. [%.2fs] | ', t, toc(tile_render_time))
            freemem
        end
    end
    
    % Save
    imwrite(sec_img, fullfile(params.path, sprintf('sec%d_%sx.tif', secs{s}.num, num2str(params.render_scale))));
    sec_img = []; % free up memory for next section
    
    if params.verbosity > 1
        fprintf('Rendered section %d (%d/%d). [%.2fs] | ', secs{s}.num, s, num_secs, toc(sec_render_time))
        freemem
    elseif params.verbosity > 0
        fprintf('Rendered section %d (%d/%d). [%.2fs]\n', secs{s}.num, s, num_secs, toc(sec_render_time))
    end
end

pctRunOnAll warning('on', 'MATLAB:nearlySingularMatrix')
warning('on', 'MATLAB:nearlySingularMatrix')

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