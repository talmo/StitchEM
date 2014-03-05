first_sec_num = 100;
num_secs = 10;

secs = cell(num_secs, 1);
matches = cell(num_secs-1, 2);
match_stats = cell(num_secs-1, 1);
merges = cell(num_secs, 1);
merges_R = cell(num_secs, 1);

%% Initialize
for i = 1:num_secs-1
    if i == 1
        [secs{i}, secs{i + 1}] = initialize_section_pair(first_sec_num + i - 1, first_sec_num + i);
    else
        [secs{i}, secs{i + 1}] = initialize_section_pair(secs{i}, first_sec_num + i);
    end
end

%% Match
for i = 1:num_secs-1
    [matchesA, matchesB, outliersA, outliersB] = match_section_pair(secs{1}, secs{i + 1});
    match_stats{i} = matching_stats(matchesA, matchesB, outliersA, outliersB);
    
    matches{i, 1} = matchesA; matches{i, 2} = matchesB;
end

%% Register
secA = secs{1};
secB = secs{2};
matchesAB = matches{1,1};
matchesBA = matches{1,2};

[tforms, mean_error] = tikhonov(vertcat(matches{:, 1}), vertcat(matches{:, 2}), 'lambda', 4e-4);

% Apply the calculated transforms to the rough tforms
for t = 1:size(tforms, 2)
    secA.fine_alignments{t} = affine2d(secA.rough_alignments{t}.T * tforms{1, t}.T);
    secB.fine_alignments{t} = affine2d(secB.rough_alignments{t}.T * tforms{2, t}.T);
end

% Look for bad transforms
scale = []; rotation = []; translation = [];
for t = 1:length(secA.fine_alignments)
    [s, r, tr] = estimate_tform_params(secA.fine_alignments{t}.T);
    scale = [scale; s]; rotation = [rotation; r]; translation = [translation; tr];
end
tile_num = (1:length(scale))';
tform_params = table(tile_num, scale, rotation, translation);
disp(tform_params)

%% Render
tile_num = 13;
[tile_matchesA, tile_matchesB] = filter_matches(matchesAB, matchesBA, 'tile', tile_num);

[tforms, mean_error] = tikhonov(tile_matchesA, tile_matchesB, 'lambda', 0.010);

tformA = affine2d(secA.rough_alignments{tile_num}.T * tforms{1, tile_num}.T);
tformB = affine2d(secB.rough_alignments{tile_num}.T * tforms{2, tile_num}.T);

[tile1, tile1_R] = imwarp(secA.img.tiles{tile_num}, tformA);
[tile2, tile2_R] = imwarp(secB.img.tiles{tile_num}, tformB);
imshowpair(tile1, tile1_R, tile2, tile2_R)
plot_matches(tforms{1, tile_num}.transformPointsForward(tile_matchesA.global_points), tforms{2, tile_num}.transformPointsForward(tile_matchesB.global_points))