function z_matches = select_z_matches(secA, secB)
%SELECT_Z_MATCHES Manually select Z matches.

alignmentA = 'z';
alignmentB = 'prev_z';

scale = 0.025;

[A, R_A] = imshow_section(secA.num, 'tforms', secA.alignments.(alignmentA).tforms, 'suppress_display', true, 'display_scale', scale);
[B, R_B] = imshow_section(secB.num, 'tforms', secB.alignments.(alignmentB).tforms, 'suppress_display', true, 'display_scale', scale);

ptsAin = [];
ptsBin = [];
%[ptsB, ptsA] = cpselect(B, A, ptsBin, ptsAin, 'Wait', true);

[ptsB, ptsA] = cpselect(B, A, 'Wait', true);

offsetA = [R_A.XWorldLimits(1), R_A.YWorldLimits(1)];
offsetB = [R_B.XWorldLimits(1), R_B.YWorldLimits(1)];

ptsA = bsxadd(ptsA, offsetA);
ptsB = bsxadd(ptsB, offsetB);

ptsA = ptsA / scale;
ptsB = ptsB / scale;

z_matches.A = table();
z_matches.B = table();
z_matches.A.global_points = ptsA;
z_matches.B.global_points = ptsB;


z_matches.num_matches = height(z_matches.A);
z_matches.method = 'manual';
z_matches.meta.avg_error = rownorm2(z_matches.B.global_points - z_matches.A.global_points);
z_matches.meta.all_displacements = z_matches.B.global_points - z_matches.A.global_points;
z_matches.meta.secA = secA.num;
z_matches.meta.alignmentA = alignmentA;
z_matches.meta.secB = secB.num;
z_matches.meta.alignmentB = alignmentB;

end

