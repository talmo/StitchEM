% Section paths
sections = {'/data/home/talmo/EMdata/W002/S2-W002_Sec100_Montage', ...
            '/data/home/talmo/EMdata/W002/S2-W002_Sec101_Montage', ...
            '/data/home/talmo/EMdata/W002/S2-W002_Sec102_Montage', ...
            '/data/home/talmo/EMdata/W002/S2-W002_Sec103_Montage', ...
            '/data/home/talmo/EMdata/W002/S2-W002_Sec104_Montage', ...
            '/data/home/talmo/EMdata/W002/S2-W002_Sec105_Montage', ...
            '/data/home/talmo/EMdata/W002/S2-W002_Sec106_Montage', ...
            '/data/home/talmo/EMdata/W002/S2-W002_Sec107_Montage', ...
            '/data/home/talmo/EMdata/W002/S2-W002_Sec108_Montage', ...
            '/data/home/talmo/EMdata/W002/S2-W002_Sec109_Montage'};

%sections = {'/data/home/talmo/EMdata/W002/S2-W002_Sec100_Montage', ...
%            '/data/home/talmo/EMdata/W002/S2-W002_Sec101_Montage'};
        
tic;
% Pre-allocate a big array for holding all the matches
matches = cell(numel(sections) - 1, 1);

% Match each pair of sections
num_matches = 0;
for a = 1:(numel(sections) - 1)
    % Initialize section pair
    secA = initialize_section(sections{a});
    secB = initialize_section(sections{a + 1});
    
    % Get matching points between sections
    matching_points = match_sections(secA, secB);
    
    % Save to cell array
    matches{a} = matching_points;
end

fprintf('\nFound matches between all %d sections in %.2fs.\n', ...
    numel(sections), toc);

pointsA = [];
pointsB = [];
for i = 1:numel(matches)
    for t = 1:16
        pointsA = [pointsA; matches{i}{t}{1}];
        pointsB = [pointsB; matches{i}{t}{2}];
    end
end

% Data structure:
%   matches{pair}{tile}{1 or 2}


% all_sections = vertcat(matches{:});
% 
% all_pointsA = vertcat(matches{:});
% all_pointsB = vertcat(matches{:});
% 
% total_num_matches = size(all_pointsA, 1);
% mean_num_matches = total_num_matches / (numel(sections) - 1);
% mean_distance = match_distances(all_pointsA, all_pointsB) / total_num_matches;
% 
% fprintf('  Total matches: %d\n', total_num_matches)
% fprintf('  Mean matches per section pair: %.1f\n', mean_num_matches)
% fprintf('  Mean distance per match: %.2f\n', mean_distance)
