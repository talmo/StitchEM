function varargout = imshow_section(sec_num, varargin)
%IMSHOW_SECTION Merges tiles that are registered to the global coordinate grid by the inputted tforms.

% Parse parameters
[sec_num, tforms, params] = parse_inputs(sec_num, varargin{:});

total_time = tic;
fprintf('Merging section %d into one image at %fx scale.\n', sec_num, params.scale)

% Turn off warnings about bad scaling
warning('off', 'MATLAB:nearlySingularMatrix')

merge = [];
for tile_num = 1:length(tforms)
    tic
    if length(params.tile_imgs) >= tile_num && ~isempty(params.tile_imgs{tile_num})
        % Tile already loaded, just apply transform with resize
        base_tform = tforms{tile_num};
        scaling_tform = scale_tform(params.scale);
        tform = affine2d(base_tform .T * scaling_tform.T);
        [tile, tile_R] = imwarp(params.tile_imgs{tile_num}, tform, 'Interp', 'cubic');
    else
        % Load and transform tile
        [tile, tile_R] = imshow_tile(sec_num, tile_num, tforms{tile_num}, params.scale, true);
    end
    
    if isempty(merge)
        % Initiliaze the merged image
        merge = tile;
        merge_R = tile_R;
    else
        % Merge tile to the previous merge
        if strcmp(params.method, 'max')
            [merge_padded,tile_padded,merge_mask,tile_mask,merge_R] = calculateOverlayImages(merge,merge_R,tile,tile_R);
            merge = max(merge_padded, tile_padded);
        else
            [merge, merge_R] = imfuse(merge, merge_R, tile, tile_R, params.method);
        end
    end
    fprintf('Merged tile %d. [%.2fs]\n', tile_num, toc)
end
fprintf('Done merging section. [%.2fs]\n', toc(total_time))

% Turn warnings about bad scaling back on
warning('on', 'MATLAB:nearlySingularMatrix')

if ~params.suppress_display
    imshow(merge, merge_R)
end

if nargout > 0
    varargout = {merge, merge_R};
end
end

function [sec_num, tforms, params] = parse_inputs(sec_num, varargin)
% Create inputParser instance
p = inputParser;

% Required parameters
p.addRequired('sec_num');

% Optional parameters
p.addOptional('tforms', {});

% Name-value pairs
p.addParameter('scale', 0.025);
p.addParameter('suppress_display', false);
p.addParameter('method', 'max');
p.addParameter('tile_imgs', {});

% Validate and parse input
p.parse(sec_num, varargin{:});
sec_num = p.Results.sec_num;
tforms = p.Results.tforms;
params = rmfield(p.Results, {'sec_num', 'tforms'});

% Initialize tiles to grid if any are missing their transforms
if any(cellfun('isempty', tforms))
    tforms = estimate_tile_grid_alignments(tforms);
end

end