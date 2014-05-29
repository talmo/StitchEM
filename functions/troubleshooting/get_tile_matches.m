function tile_matches = get_tile_matches(matches, tile_nums)
%GET_TILE_MATCHES Splits the matches table into a cell array of match tables for each tile.
% Usage:
%   tile_matches = get_tile_matches(matches)
%   tile_matches = get_tile_matches(matches, tile_nums)
%
% See also: tile_match_idx

% Get tile match indices
if nargin > 1
    idx = tile_match_idx(matches, tile_nums);
else
    [idx, tile_nums] = tile_match_idx(matches);
end

% Make sure idx is a cell
if ~iscell(idx)
    idx = {idx};
end

% Create separate tables for each tile
tile_matches = cellfun(@(tidx) struct('A', matches.A(tidx, :), 'B', matches.B(tidx, :)), idx, 'UniformOutput', false);

% Scalar output
if numel(tile_nums) == 1
    tile_matches = tile_matches{1};
end
end

