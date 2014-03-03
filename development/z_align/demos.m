%% Match sections a pair of sections
sec_num = 1;

% Load images
secA = sec_struct(sec_num);
secB = sec_struct(sec_num + 1);

% Match
[matchesAB, matchesBA, secA, secB] = match_section_pair(secA, secB, 'show_matches', true);

%% Match three consecutive sections
sec_num = 55;

% Load images
secA = sec_struct(sec_num);
secB = sec_struct(sec_num + 1);

% Match first pair
[matchesAB, matchesBA, secA, secB, mergeAB, mergeAB_R] = match_section_pair(secA, secB, 'show_matches', true);

secC = sec_struct(sec_num + 2);

% Match second pair
[matchesBC, matchesCB, secB, secC, mergeBC, mergeBC_R] = match_section_pair(secB, secC, 'show_matches', true);
