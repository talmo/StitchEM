function imshow_section_pair(i, j, load_cached, scale)
%IMSHOW_SECTION_PAIR Loads and shows a pair of sections.

if nargin < 3
    load_cached = true;
end
if nargin < 4
    scale = 0.025;
end

if load_cached
    i = load_sec(i); sec_num_i = i.num;
    j = load_sec(j); sec_num_j = j.num;
else
    sec_num_i = i;
    sec_num_j = j;
end

[secI, secI_R] = imshow_section(i, 'suppress_display', true, 'display_scale', scale);
[secJ, secJ_R] = imshow_section(j, 'suppress_display', true, 'display_scale', scale);

imshowpair(secI, secI_R, secJ, secJ_R)
title(sprintf('Sections %d (green) and %d (purple)', sec_num_i, sec_num_j))
integer_axes(1 / scale)

end

