sec_nums = 31:86;

secs = cell(length(sec_nums), 1);
matchesA = cell(length(sec_nums), 1);
matchesB = cell(length(sec_nums), 1);
last_sec = [];
for i = 1:length(sec_nums)
    sec_time = tic;
    
    % Load sec from cache
    sec = load_sec(sec_nums(i));
    
    % Match XY features
    try
        [matchesA{i}, matchesB{i}] = match_section_features(sec, 'show_matches', false);
    catch
        warning('Failed to find XY matches in section %d. Verify rough alignment.\n\n', sec.num)
        continue
    end
    
    % Match Z features
    if ~isempty(last_sec)
        [z_matchesA, z_matchesB] = match_section_pair(sec, last_sec, 'show_matches', false);
        matchesA{i} = [matchesA{i}; z_matchesA];
        matchesB{i} = [matchesB{i}; z_matchesB];
    end
    
    last_sec = sec;
    sec.xy_features = []; sec.z_features = [];
    secs{i} = sec;
    fprintf('Found matches in section %d. [%.2fs]\n\n', sec.num, toc(sec_time))
end

% Merge match tables
matchesA = vertcat(matchesA{:});
matchesB = vertcat(matchesB{:});

%% Save
save(sprintf('sec%d-%d_matches.mat', sec_nums(1), sec_nums(end)), ...
    'secs', 'matchesA', 'matchesB')