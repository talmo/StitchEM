function tile_set = closest_tileset(sec, scale)
%CLOSEST_TILESET Returns the name of the tile set in the section closest to the specified detection scale.
% Usage:
%   tile_set = closest_tileset(sec, scale)
%
% See also: load_section

if ~isstruct(sec) || ~isfield(sec, 'tiles')
    error('Could not find tile sets. Make sure the section structure was created by load_section.')
end

% Get names of tile sets
tile_sets = fieldnames(sec.tiles);

% Get the scale of each tile set
scales = cellfun(@(s) sec.tiles.(s).scale, tile_sets);

% Find the closest scale that is >= the desired scale
[~, idx] = min(scales(scales >= scale));

% Couldn't find any tile sets matching criteria
if isempty(idx)
    error('None of the tile sets in the structure are of greater or equal scale to the specified scale.')
end

% Return tile set
tile_set = tile_sets{idx};

end

