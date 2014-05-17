% Goal: Look into the actual performance of rough alignment in Z
%% Configuration
% These must have all their alignments done
s = 3;
secA = secs{s - 1};
secB = secs{s};

%% Calculate pre and post errors for rough Z alignment
results = table();

for s = 2:length(secs)
    secA = secs{s - 1};
    secB = secs{s};
    
    matches = secB.z_matches;
    ptsA = secB.z_matches.A.global_points;

    % Pre
    xy_tforms = secB.alignments.xy.tforms;
    pts_xy_aligned = zeros(size(matches.B.local_points));
    for i = 1:height(pts_xy_aligned)
        pts_xy_aligned(i, :) = xy_tforms{matches.B.tile(i)}.transformPointsForward(matches.B.local_points(i, :));
    end
    xy_error = rownorm2(pts_xy_aligned - ptsA);

    % Post
    rough_z_tforms = secB.alignments.rough_z.tforms;
    pts_rough_z_aligned = matches.B.global_points;
    rough_z_error = rownorm2(pts_rough_z_aligned - ptsA);

    % Z
    z_tforms = secB.alignments.z.tforms;
    z_rel_tform = secB.alignments.z.rel_tforms{1}; % same for all tiles
    pts_z_aligned = z_rel_tform.transformPointsForward(pts_rough_z_aligned);
    z_error = rownorm2(pts_z_aligned - ptsA);

    % Summarize results
    sec_results = table(s, xy_error, rough_z_error, z_error);
    %disp(sec_results)
    results = [results; sec_results];
end
disp(results)

%% Plot errors
figure, subaxis(1, 2, 1)
plot([results.xy_error, results.rough_z_error, results.z_error]', 'x-')
title('Alignment Error'), ylabel('Error (px / match)')
set(gca, 'XTick', 1:3), set(gca, 'XTickLabel', {'xy', 'rough_z', 'z'})

% Relative error change
subaxis(1, 2, 2)
plot(bsxadd([results.xy_error, results.rough_z_error, results.z_error], -results.xy_error)', 'x-')
hold on, plot(1:3, zeros(1, 3), 'k--'), hold off
title('Alignment Error (relative to xy)'), ylabel('\delta Error (px / match)')
set(gca, 'XTick', 1:3), set(gca, 'XTickLabel', {'xy', 'rough_z', 'z'})

%% Displacement plots
% Displacements
D_xy = pts_xy_aligned - ptsA;
D_rough_z = pts_rough_z_aligned - ptsA;
D_z = pts_z_aligned - ptsA;

figure
subaxis(1, 3, 1), plot_displacements(D_xy), title('xy')
subaxis(1, 3, 2), plot_displacements(D_rough_z), title('rough\_z')
subaxis(1, 3, 3), plot_displacements(D_z), title('z')
set(gcf, 'Position', [46, 347, 1849, 547])

%% Match plots
figure
subaxis(1, 3, 1), plot_section(secA, 'z', 'r0.1'), plot_section(secB, 'xy', 'g0.1'), plot_matches(ptsA, pts_xy_aligned), title('xy')
subaxis(1, 3, 2), plot_section(secA, 'z', 'r0.1'), plot_section(secB, 'rough_z', 'g0.1'), plot_matches(ptsA, pts_rough_z_aligned), title('rough_z')
subaxis(1, 3, 3), plot_section(secA, 'z', 'r0.1'), plot_section(secB, 'z', 'g0.1'), plot_matches(ptsA, pts_z_aligned), title('z')
set(gcf, 'Position', [46, 347, 1849, 547])

%% Error distributions
[~, norms_xy] = rownorm2(pts_xy_aligned - ptsA);
[~, norms_rough_z] = rownorm2(pts_rough_z_aligned - ptsA);
[~, norms_z] = rownorm2(pts_z_aligned - ptsA);

figure
subaxis(1, 3, 1), hist(norms_xy, 20), title('xy')
subaxis(1, 3, 2), hist(norms_rough_z, 20), title('rough\_z')
subaxis(1, 3, 3), hist(norms_z, 20), title('z')
set(gcf, 'Position', [46, 347, 1849, 547])