function varargout = imshow_overview(section_num, suppress_display)
%IMSHOW_OVERVIEW Shows the montage overview image for a section.

if nargin < 2
    suppress_display = false;
end

montage_img = imload_overview(section_num);

if ~suppress_display
    imshow(montage_img)
end

if nargout > 0
    varargout = {montage_img};
end
end

