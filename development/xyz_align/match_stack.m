% Loads cached features for a stack of sections, matches them and saves the matches.
% Note: Doesn't save the features.

%% Parameters
sec_nums = 1:149;
cache_path = './sec_cache'; % Load features from here

%% Matching
% Initialize containers
secs = cell(length(sec_nums), 1);
matchesA = cell(length(sec_nums), 1);
matchesB = cell(length(sec_nums), 1);

% Keep track of failures and statistics
failed_tile_pairs = cell(length(sec_nums), 1);
failed_xy_matching = {};
failed_section_pairs = {};
num_xy_matches = zeros(length(sec_nums), 1);
num_z_matches = zeros(length(sec_nums), 1);

% Match
last_sec = [];
for i = 1:length(sec_nums)
    sec_time = tic;
    
    % Load sec from cache
    try
        sec = load_sec(sec_nums(i), 'cache_path', cache_path);
    catch
        warning('Unable to load section %d/%d.', i, length(sec_nums))
        continue
    end
    
    % Match XY features
    try
        [xy_matchesA, xy_matchesB, failed_tile_pairs{i}] = match_section_features(sec, 'show_matches', false);
        
        matchesA{i} = [matchesA{i}; xy_matchesA];
        matchesB{i} = [matchesB{i}; xy_matchesB];
        num_xy_matches(i) = height(xy_matchesA);
    catch
        warning('Failed to find XY matches in section %d. Verify rough alignment.', sec.num)
        failed_xy_matching{end + 1} = sec.num;
    end
    
    % Match Z features
    if ~isempty(last_sec) && ~isempty(last_sec.z_features)
        try
            [z_matchesA, z_matchesB] = match_section_pair(sec, last_sec, 'show_matches', false);
            
            matchesA{i} = [matchesA{i}; z_matchesA];
            matchesB{i} = [matchesB{i}; z_matchesB];
            num_z_matches(i) = height(z_matchesA);
        catch
            warning('Failed to find Z matches in section %d with section %d.', sec.num, last_sec.num)
            failed_section_pairs{end + 1} = [sec.num, last_sec.num];
        end
    end
    
    last_sec = sec;
    sec.xy_features = []; sec.z_features = [];
    secs{i} = sec;
    fprintf('Done matching section %d. [%.2fs]\n\n', sec.num, toc(sec_time))
end

% Merge match tables
matchesA = vertcat(matchesA{:});
matchesB = vertcat(matchesB{:});

%% Save
save(sprintf('match_sets/sec%d-%d_matches.mat', sec_nums(1), sec_nums(end)), ...
    'secs', 'matchesA', 'matchesB')
save(sprintf('sec%d-%d_matching_data.mat', sec_nums(1), sec_nums(end)), 'failed_tile_pairs', 'failed_xy_matching', 'failed_section_pairs', 'num_xy_matches', 'num_z_matches')