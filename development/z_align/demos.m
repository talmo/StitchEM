%% Match sections a pair of sections
sec_num = 1;

% Load images
secA = sec_struct(sec_num);
secB = sec_struct(sec_num + 1);

% Match
[matchesAB, matchesBA, secA, secB] = match_section_pair(secA, secB, 'show_matches', true);

%% Match three consecutive sections
sec_num = 100;

% Load images
secA = sec_struct(sec_num);
secB = sec_struct(sec_num + 1);

% Match first pair
[matchesAB, matchesBA, secA, secB, mergeAB, mergeAB_R] = match_section_pair(secA, secB, 'show_matches', true);

secC = sec_struct(sec_num + 2);

% Match second pair
[matchesBC, matchesCB, secB, secC, mergeBC, mergeBC_R] = match_section_pair(secB, secC, 'show_matches', true);

%% Registration
tforms = tikhonov(matchesBC, matchesCB, 'lambda', 0.0005);

scale = 0.075;

figure
[mergeB, mergeB_R] = imshow_section(secB.num, tforms(1,:), 'tile_imgs', secB.img.tiles, 'scale', scale, 'suppress_display', true);
figure
[mergeC, mergeC_R] = imshow_section(secC.num, tforms(2,:), 'tile_imgs', secC.img.tiles, 'scale', scale, 'suppress_display', true);

% Transforms matches
registered_pts_B = zeros(size(matchesBC, 1));
registered_pts_C = zeros(size(matchesCB, 1));
for t = 1:size(tforms, 2)
    idxBC = find(matchesBC.tile == t);
    registered_pts_B(idxBC, :) = tforms{1, t}.transformPointsForward(matchesBC.global_points(idxBC, :));
    
    idxCB = find(matchesCB.tile == t);
    registered_pts_C(idxCB, :) = tforms{2, t}.transformPointsForward(matchesCB.global_points(idxCB, :));
end

mean_error = sum(calculate_match_distances(registered_pts_B, registered_pts_C)) / size(matchesBC, 1);
fprintf('mean error = %fpx\n', mean_error)

figure
imshowpair(mergeB, mergeB_R, mergeC, mergeC_R), hold on
plot_matches(registered_pts_B, registered_pts_C, scale)
hold off