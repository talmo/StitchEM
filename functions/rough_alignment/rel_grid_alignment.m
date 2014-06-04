function alignment = rel_grid_alignment(sec, fixed_tforms, rel_to, overlap)
%REL_GRID_ALIGNMENT Returns an alignment where tiles are aligned to the grid relative to their fixed neighbors.
% Usage:
%   alignment = rel_grid_alignment(sec)
%   alignment = rel_grid_alignment(sec, fixed_tforms)
%   alignment = rel_grid_alignment(sec, fixed_tforms, rel_to)
%   alignment = rel_grid_alignment(sec, fixed_tforms, rel_to, overlap)

% Default
if nargin < 2
    fixed_tforms = cell(sec.num_tiles, 1);
end
if nargin < 3
    rel_to = 'initial';
end
if nargin < 4
    overlap = 0.1;
end
rel_to = validatestring(rel_to, fieldnames(sec.alignments));
base_tforms = sec.alignments.(rel_to).tforms;
assert(length(fixed_tforms) == length(base_tforms), 'Fixed transforms must be of the same size as relative transforms.')


% Find fixed tiles
fixed = ~areempty(fixed_tforms);

% Fix first tile if no tiles are fixed
if ~any(fixed)
    fixed(1) = 1;
    fixed_tforms{1} = affine2d();
end
fixed_tiles = find(fixed);

% Initialize to set of fixed tforms
rel_tforms = fixed_tforms;

% Loop through tiles missing transforms
for t = 1:length(rel_tforms)
    % Skip fixed tiles
    if ~isempty(rel_tforms{t}); continue; end
    
    % Get grid distance to fixed tiles
    dists = arrayfun(@(t2) dist2(t, t2, sec.grid), fixed_tiles);
    
    % Find closest fixed grid neighbors
    neighbors = fixed_tiles(dists == min(dists));
    
    % Get current tile's position and size after base transform
    [sz_t, pos_t] = tform_sz(sec.tile_sizes{t}, base_tforms{t});
    
    % Calculate offsets relative to each neighbor
    tx = zeros(length(neighbors), 1);
    ty = zeros(length(neighbors), 1);
    for i = 1:length(neighbors)
        n = neighbors(i);
        
        % Compose fixed with the base transform
        tform_n = compose_tforms(base_tforms{n}, fixed_tforms{n});
        
        % Find neighbor position and size after transform
        [sz_n, pos_n] = tform_sz(sec.tile_sizes{n}, tform_n);
        
        % Get grid coordinate displacements
        [dI, dJ] = dist2(t, n, sec.grid);
        
        % Calculate offsets
        tx(i) = (pos_n(1) - pos_t(1)) + ...
                -sign(dJ) * sz_n(2) * (1 - overlap) + ...
                -(dJ - sign(dJ)) * sz_t(2) * (1 - overlap);
        
        ty(i) = (pos_n(2) - pos_t(2)) + ...
                -sign(dI) * sz_n(1) * (1 - overlap) + ...
                -(dI - sign(dI)) * sz_t(1) * (1 - overlap);
    end
    
    % Translate tile by mean offset
    tx = mean(tx); ty = mean(ty);
    rel_tforms{t} = make_tform('translate', tx, ty);
end

% Compose with base transform
tforms = compose_tforms(base_tforms, rel_tforms);

% Alignment structure
alignment.tforms = tforms;
alignment.rel_tforms = rel_tforms;
alignment.rel_to = rel_to;
alignment.meta.overlap_assumed = overlap;
alignment.meta.fixed_tiles = fixed_tiles;

end

function [sz, pos] = tform_sz(sz, tform)
[XLims, YLims] = sz2lims(sz);
[XLims, YLims] = tform.outputLimits(XLims, YLims);
sz = [diff(YLims), diff(XLims)];
pos = [min(XLims), min(YLims)];
end