function orphans = find_orphan_tiles(sec, matches)
%FIND_ORPHAN_TILES Find tiles with no matches.
% Usage:
%   orphans = find_orphan_tiles(sec, 'xy')
%   orphans = find_orphan_tiles(sec, 'z')

switch matches
    case 'xy'
        orphans = setdiff(sec.grid(sec.grid > 0), union(unique(sec.xy_matches.A.tile), unique(sec.xy_matches.B.tile)));
    case 'z'
        orphans = setdiff(sec.grid(sec.grid > 0), unique(sec.z_matches.B.tile));
end
end

