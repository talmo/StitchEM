function imshow_section_matches(matchesA, matchesB, sec_num_A, sec_num_B, scale)
%IMSHOW_SECTION_MATCHES Renders a section and its matches.


if nargin < 4
    sec_num_B = sec_num_A; % XY matches
end
if nargin < 5
    scale = 0.025;
end

i = sec_num_A; j = sec_num_B;
imshow_section(load_sec(i), 'display_scale', scale);
ptsA = matchesA(matchesA.section == i & matchesB.section == j, 'global_points');
ptsB = matchesB(matchesA.section == i & matchesB.section == j, 'global_points');
plot_matches(ptsA, ptsB, scale)

if i == j % XY matches
    title(sprintf('Matches in section %d (n = %d)', i, size(ptsA, 1)))
else
    title(sprintf('Matches in section %d with section %d (n = %d)', i, j, size(ptsA, 1)))
end

end

