%% Initialize, match and display merge for pair of sections
% Initialize pair of sections
[sec1, sec2] = initialize_section_pair(1, 2);

% Match the sections
[matches1, matches2] = match_section_pair(sec1, sec2, 'show_matches', true);

%% Initialize three consecutive sections
sec_num = 100;

% Initialize first pair
[secA, secB] = initialize_section_pair(sec_num, sec_num + 1);

% Initialize second pair
[secB, secC] = initialize_section_pair(secB, sec_num + 2);

%% Match them
% Match first pair
[matchesAB, matchesBA, outliersAB, outliersBA, mergeAB, mergeAB_R] = match_section_pair(secA, secB, 'show_matches', true);
match_statsAB = matching_stats(matchesAB, matchesBA, outliersAB, outliersBA);
disp(match_statsAB.tile_summary)

% Match second pair
[matchesBC, matchesCB, outliersBC, outliersCB, mergeBC, mergeBC_R] = match_section_pair(secB, secC, 'show_matches', true);
match_statsBC = matching_stats(matchesBC, matchesCB, outliersAB, outliersBA);
disp(match_statsBC.tile_summary)
%% Registration
lambdas = (10 .^ (-3:0.1:5));
registrations_errors = [];
for lambda = lambdas
    fprintf('\n\n==>lambda = %s\n', num2str(lambda))
    tforms = tikhonov_old(matchesAB, matchesBA, 'lambda', lambda);

    % Apply the calculated transforms to the rough tforms
    for t = 1:size(tforms, 2)
        secA.fine_alignments{t} = affine2d(secA.rough_alignments{t}.T * tforms{1, t}.T);
        secB.fine_alignments{t} = affine2d(secB.rough_alignments{t}.T * tforms{2, t}.T);
    end
    
    % Look for bad transforms
    tile_num = (1:length(scale))'; scale = []; rotation = []; translation = [];
    for t = 1:length(secA.fine_alignments)
        [s, r, tr] = estimate_tform_params(secA.fine_alignments{t}.T);
        scale = [scale; s]; rotation = [rotation; r]; translation = [translation; tr];
    end
    tform_params = table(tile_num, scale, rotation, translation);
    disp(tform_params)
    
    % Transforms matches
    registered_pts_A = zeros(size(matchesAB, 1), 2); registered_pts_B = zeros(size(matchesAB, 1), 2);
    for t = 1:size(tforms, 2)
        tile_matchesAB = matchesAB.id(matchesAB.tile == t);
        local_pointsAB = secA.features.local_points(tile_matchesAB, :);
        registered_pts_A(matchesAB.tile == t, 1:2) = secA.fine_alignments{t}.transformPointsForward(local_pointsAB);

        tile_matchesBA = matchesBA.id(matchesBA.tile == t);
        local_pointsBA = secB.features.local_points(tile_matchesBA, :);
        registered_pts_B(matchesBA.tile == t, 1:2) = secB.fine_alignments{t}.transformPointsForward(local_pointsBA);
    end

    mean_error = sum(calculate_match_distances(registered_pts_A, registered_pts_B)) / size(matchesAB, 1);
    fprintf('mean error = %fpx\n', mean_error)
    
    registrations_errors = [registrations_errors mean_error];
end
semilogx(lambdas,registrations_errors)

%% Register sections

tforms = tikhonov([matchesAB; matchesBC], [matchesBA; matchesCB], 'lambda', 0.09);

% Apply the calculated transforms to the rough tforms
for t = 1:size(tforms, 2)
    secA.fine_alignments{t} = affine2d(secA.rough_alignments{t}.T * tforms{1, t}.T);
    secB.fine_alignments{t} = affine2d(secB.rough_alignments{t}.T * tforms{2, t}.T);
end

% Look for bad transforms
tile_num = (1:length(scale))'; scale = []; rotation = []; translation = [];
for t = 1:length(secA.fine_alignments)
    [s, r, tr] = estimate_tform_params(secA.fine_alignments{t}.T);
    scale = [scale; s]; rotation = [rotation; r]; translation = [translation; tr];
end
tform_params = table(tile_num, scale, rotation, translation);
disp(tform_params)

% Transforms matches
registered_pts_A = zeros(size(matchesAB, 1), 2); registered_pts_B = zeros(size(matchesAB, 1), 2);
for t = 1:size(tforms, 2)
    tile_matchesAB = matchesAB.id(matchesAB.tile == t);
    local_pointsAB = secA.features.local_points(tile_matchesAB, :);
    registered_pts_A(matchesAB.tile == t, 1:2) = secA.fine_alignments{t}.transformPointsForward(local_pointsAB);

    tile_matchesBA = matchesBA.id(matchesBA.tile == t);
    local_pointsBA = secB.features.local_points(tile_matchesBA, :);
    registered_pts_B(matchesBA.tile == t, 1:2) = secB.fine_alignments{t}.transformPointsForward(local_pointsBA);
end

mean_error = sum(calculate_match_distances(registered_pts_A, registered_pts_B)) / size(matchesAB, 1);
fprintf('mean error = %fpx\n', mean_error)

%% Render transformed sections
display_scale = 0.025;
[mergeA, mergeA_R] = imshow_section(secA, secA.fine_alignments, 'display_scale', display_scale, 'suppress_display', true);
[mergeB, mergeB_R] = imshow_section(secB, secB.fine_alignments, 'display_scale', display_scale, 'suppress_display', true);

figure
imshowpair(mergeA, mergeA_R, mergeB, mergeB_R), hold on
plot_matches(registered_pts_A, registered_pts_B, display_scale)
hold off

%% Test case: single tile
tile_num = 13;
[tile_matchesA, tile_matchesB] = filter_matches(matchesAB, matchesBA, 'tile', tile_num);

lambdas = (10 .^ (-6:0.1:3));
registrations_errors = [];
for lambda = lambdas
    %[tforms, mean_error] = tikhonov_old(tile_matchesA, tile_matchesB, 'lambda', lambda, 'num_tiles', 1);
    [tforms, mean_error] = tikhonov(tile_matchesA, tile_matchesB, 'lambda', lambda);
    
    registrations_errors = [registrations_errors mean_error];
end
semilogx(lambdas,registrations_errors)

%% Apply transform and render
tile_num = 13;
[tile_matchesA, tile_matchesB] = filter_matches(matchesAB, matchesBA, 'tile', tile_num);

[tforms, mean_error] = tikhonov(tile_matchesA, tile_matchesB, 'lambda', 0.010);

tformA = affine2d(secA.rough_alignments{tile_num}.T * tforms{1, tile_num}.T);
tformB = affine2d(secB.rough_alignments{tile_num}.T * tforms{2, tile_num}.T);

[tile1, tile1_R] = imwarp(secA.img.tiles{tile_num}, tformA);
[tile2, tile2_R] = imwarp(secB.img.tiles{tile_num}, tformB);
imshowpair(tile1, tile1_R, tile2, tile2_R)
plot_matches(tforms{1, tile_num}.transformPointsForward(tile_matchesA.global_points), tforms{2, tile_num}.transformPointsForward(tile_matchesB.global_points))

%% Render pre-alignment
% Render (before)
[tile1, tile1_R] = imwarp(secA.img.tiles{tile_num}, secA.rough_alignments{tile_num});
[tile2, tile2_R] = imwarp(secB.img.tiles{tile_num}, secB.rough_alignments{tile_num});
figure, imshowpair(tile1, tile1_R, tile2, tile2_R)
plot_matches(tile_matchesA, tile_matchesB.global_points)

%% Alternative: pairwise
tile_num = 13;
[tile_matchesA, tile_matchesB] = filter_matches(matchesAB, matchesBA, 'tile', tile_num);

% Estimate transforms
tformA = secA.rough_alignments{tile_num};
%tformB = fitgeotrans(tile_matchesB.global_points, tile_matchesA.global_points, 'affine');
tformB = estimateGeometricTransform(tile_matchesB.global_points,tile_matchesA.global_points, 'affine');

% Apply transforms to points
mean_error = calculate_registration_error(tile_matchesA.global_points, tile_matchesB.global_points, tformB);
fprintf('mean error = %fpx\n', mean_error)

% Render
tformB_adjusted = affine2d(secB.rough_alignments{tile_num}.T * tformB.T);
[tile1, tile1_R] = imwarp(secA.img.tiles{tile_num}, tformA);
[tile2, tile2_R] = imwarp(secB.img.tiles{tile_num}, tformB_adjusted);
figure, imshowpair(tile1, tile1_R, tile2, tile2_R)
plot_matches(tile_matchesA, tformB.transformPointsForward(tile_matchesB.global_points))

