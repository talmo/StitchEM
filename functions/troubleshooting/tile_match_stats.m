function stats = tile_match_stats(matches, tile_nums)
%TILE_MATCH_STATS Returns some basic statistics for the matches split up per tile.
% Usage:
%   stats = tile_match_stats(matches)
%   stats = tile_match_stats(matches, tile_nums)

if ~isstruct(matches) || ~isfield(matches, 'A') || ~isfield(matches, 'B')
    error('Parameter ''matches'' must specify a valid matches structure.')
end

% Get the index of the matches in each tile
if nargin < 2
    [idx, tile_nums] = tile_match_idx(matches);
else
    idx = tile_match_idx(matches, tile_nums);
end
stats.tile_nums = tile_nums;

% Number of matches
stats.num_matches = cellfun(@length, idx);

% Match error
stats.match_error = arrayfun(@(t) rownorm2(matches.B.global_points(idx{t},:) - matches.A.global_points(idx{t},:)), stats.tile_nums);

if nargin > 1
    % Format into grid
    for f = fieldnames(stats)'
        field = stats.(f{1});
        stats.(f{1}) = arrayfun(@(t) field(t), tile_nums);
    end
end

end

