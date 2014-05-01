first_sec = 100;
num_secs = 5;
failed = [];

for sec_num = first_sec:first_sec + num_secs
    try
        % Load section images
        sec = sec_struct(sec_num, 0.78 * 0.07);

        % Register tiles to section overview
        [sec.rough_alignments, sec.grid_aligned] = rough_align_tiles(sec);

        % Detect features
        sec.features = detect_section_features(sec, 'MetricThreshold', 11000);

        % Match
        [matchesA, matchesB] = match_section_features(sec, 'show_matches', false, ...
            'MatchThreshold', 0.2, 'MaxRatio', 0.6);

        % Align
        %lambda_curve(matchesA, matchesB);
        sec = align_section_tiles(sec, matchesA, matchesB, 'lambda', 0.05);

        % Render
        rough_merge = imshow_section(sec, 'tforms', 'rough', 'suppress_display', true, 'display_scale', 0.78 * 0.07);
        %imwrite(rough_merge, sprintf('rough/sec%d_rough_align.png', sec_num))
        fine_merge = imshow_section(sec, 'tforms', 'fine', 'suppress_display', true, 'display_scale', 0.78 * 0.07);
        %imwrite(fine_merge, sprintf('fine/sec%d_fine_align.png', sec_num))
    catch
        failed(end + 1) = sec_num;
        continue
    end
end