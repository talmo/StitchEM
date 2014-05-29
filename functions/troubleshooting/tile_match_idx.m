function [idx, tile_nums] = tile_match_idx(matches, tile_nums, mode)
%TILE_MATCH_IDX Returns the indices of the rows in the matches table that corresponds to each tile.
% Usage:
%   [idx, tile_nums] = tile_match_idx(matches)
%   [idx, tile_nums] = tile_match_idx(matches, tile_nums)
%   [idx, tile_nums] = tile_match_idx(matches, tile_nums, mode)
%
% Args:
%   matches: a match structure with fields A and B
%   tile_nums: a numeric array specifying which tiles to look for. If empty
%       or not specified, the unique tile numbers in the match tables is
%       detected.
%   mode:   'either' (default), idx{t} is where either A or B matches are from tile t
%           'both', idx{t} is where both A and B matches are from tile t
%           'A', idx{t} is where A matches are from tile t
%           'B', idx{t} is where B matches are from tile t
%
% Returns:
%   idx: a cell array of numerical indices in matches (or numeric if a
%       single tile number was specified).
%   tile_nums: an array containing the tile numbers searched for
%
% See also: get_tile_matches, tile_match_stats

if nargin < 2
    tile_nums = [];
end
if nargin < 3
    mode = 'either';
end

switch mode
    case 'either'
        if isempty(tile_nums); tile_nums = sort(unique([unique(matches.A.tile); unique(matches.B.tile)])); end
        idx = arrayfun(@(t) find(matches.A.tile == t | matches.B.tile == t), tile_nums, 'UniformOutput', false);
    case 'both'
        if isempty(tile_nums); tile_nums = sort(unique([unique(matches.A.tile); unique(matches.B.tile)])); end
        idx = arrayfun(@(t) find(matches.A.tile == t & matches.B.tile == t), tile_nums, 'UniformOutput', false);
    case {'A', 'B'}
        if isempty(tile_nums); tile_nums = sort(unique(matches.(mode).tile)); end
        idx = arrayfun(@(t) find(matches.(mode).tile == t), tile_nums, 'UniformOutput', false);
    otherwise
        error('Invalid mode specified.')
end

if numel(tile_nums) == 1
    idx = idx{1};
end
end

