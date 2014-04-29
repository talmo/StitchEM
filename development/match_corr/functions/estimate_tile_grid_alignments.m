function rough_alignments = estimate_tile_grid_alignments(rough_alignments, varargin)
%ESTIMATE_TILE_GRID_ALIGNMENTS Figures out where to place tiles on a grid based on initialized transforms for its neighbors.

% Parse parameters
if nargin > 0
    [rough_alignments, params] = parse_inputs(rough_alignments, varargin{:});
else
    [rough_alignments, params] = parse_inputs({});
end

% Reshape the alignments array to fit the grid
rough_alignments = reshape(rough_alignments, params.grid_size(1), params.grid_size(2))';

% Find the registered tiles (tiles with transforms)
registered_tiles = cellfun(@(x) ~isempty(x), rough_alignments);

% Align tiles based on grid
for r = 1:params.grid_size(1)
    for c = 1:params.grid_size(2)
        if isempty(rough_alignments{r, c})
            if any(any(registered_tiles))
                % Get the coordinates of the non-empty tiles
                [R, C] = find(registered_tiles);
                
                % Find the closest tile
                grid_dist = sqrt(sum([R-r C-c] .^2, 2));
                [~, idx] = min(grid_dist);
                r2 = R(idx); c2 = C(idx);
                
                % Get that tile's transform
                base_tform = rough_alignments{r2, c2};
                
                % Calculate a translation offset
                tx = (c - c2) * (1 - params.tile_overlap_ratio) * params.tile_size(1);
                ty = (r - r2) * (1 - params.tile_overlap_ratio) * params.tile_size(2);
                tform_translate = make_tform('translate', tx, ty);
                if params.verbosity > 0; fprintf('Aligned tile [%d, %d] to [%d, %d]: tx = %f, ty = %f\n', r, c, r2, c2, tx, ty); end
                
                % Roughly align current tile by translating from the base tile
                rough_alignments{r, c} = affine2d(tform_translate.T * base_tform.T);
            else
                % No tiles are registered, initialize to identity
                rough_alignments{r, c} = affine2d();
                
                % Fix this tile so all other tiles are aligned to it
                registered_tiles(r, c) = 1;
                if params.verbosity > 0; fprintf('[%d, %d] -> eye(3)\n', r, c); end
            end
        end
    end
end

% Flatten the alignments array before returning
rough_alignments = reshape(rough_alignments.', [], 1);
end

function [rough_alignments, params] = parse_inputs(rough_alignments, varargin)
% Create inputParser instance
p = inputParser;

% Optional parameters
p.addOptional('rough_alignments', {});

% Grid specification
p.addParameter('grid_size', [4 4]);
p.addParameter('tile_size', [8000 8000]);
p.addParameter('tile_overlap_ratio', 0.1);

% Debugging/development
p.addParameter('verbosity', 0);

% Validate and parse input
p.parse(rough_alignments, varargin{:});
rough_alignments = p.Results.rough_alignments;
params = rmfield(p.Results, 'rough_alignments');

% Make sure rough_alignments is the right size
num_tiles = params.grid_size(1) * params.grid_size(2);
if length(rough_alignments) < num_tiles
    rough_alignments = [rough_alignments; cell(num_tiles - length(rough_alignments), 1)];
end
end