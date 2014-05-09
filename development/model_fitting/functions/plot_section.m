function plot_section(sec, alignment)
%PLOT_SECTION Plots the bounding boxes of the section tiles.
% Usage:
%   plot_section(sec)
%   plot_section(sec, alignment)

if nargin < 2
    bounding_boxes = sec_bb(sec);
else
    bounding_boxes = sec_bb(sec, alignment);
end

plot_regions(bounding_boxes)

if nargin < 2
    title(sprintf('Section %d', sec.num))
else
    title(sprintf('Section %d | Alignment: %s', sec.num, alignment))
end

end

