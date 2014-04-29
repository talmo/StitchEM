function xy_matches = load_xy_matches(sec)
%LOAD_XY_MATCHES Loads cached XY matches for a section.

if exist(sec.xy_matches_path, 'file')
    cache = load(sec.xy_matches_path, 'xy_matches');
    xy_matches = cache.xy_matches;
else
    error(['No cached XY matches were found.\n' ...
        '\tPath: %s'], sec.xy_matches_path)
end

% Display output message and log
msg = sprintf('Loaded %d XY matches for %s (saved on %s).', xy_matches.num_matches, sec.name, datestr(xy_matches.timestamp));
fprintf('%s\n', msg)
stitch_log(msg, sec.data_path);


end

