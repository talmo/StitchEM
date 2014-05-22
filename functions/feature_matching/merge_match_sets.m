function merged = merge_match_sets(matches)
%MERGE_MATCH_SETS Returns a merged table of matches with additional columns.
% Usage:
%   merged = merge_match_sets(matches)
%
% See also: match_z, match_xy

match_sets = matches.match_sets;

if isfield(matches, 'sec')
    % XY
    sec_numA = matches.sec;
    sec_numB = matches.sec;
else
    % Z
    sec_numA = matches.secA;
    sec_numB = matches.secB;
end


% Merge section matches into a single table
merged.A = table();
merged.B = table();

% Global points
merged.A.global_points = cell2mat(cellfun(@(m) m.A.global_points, match_sets, 'UniformOutput', false));
merged.B.global_points = cell2mat(cellfun(@(m) m.B.global_points, match_sets, 'UniformOutput', false));

% Tile
merged.A.tile = cell2mat(cellfun(@(m) repmat(m.tileA, m.num_matches, 1), match_sets, 'UniformOutput', false));
merged.B.tile = cell2mat(cellfun(@(m) repmat(m.tileB, m.num_matches, 1), match_sets, 'UniformOutput', false));

% Section
merged.A.section = repmat(sec_numA, matches.num_matches, 1);
merged.B.section = repmat(sec_numB, matches.num_matches, 1);


end

