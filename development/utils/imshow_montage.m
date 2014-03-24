function montage_img = imshow_montage(section_num, suppress_display)
%IMSHOW_MONTAGE Shows the montage overview image for a section.

if nargin < 2
    suppress_display = false;
end

%data_path = '/data/home/talmo/EMdata/W002';
data_path = 'C:\Users\Talmo\Desktop';
section_path = fullfile(data_path, sprintf('S2-W002_Sec%d_Montage', section_num));
montage_path = fullfile(section_path, sprintf('MontageOverviewImage_S2-W002_sec%d.tif', section_num));

montage_img = imread(montage_path);

if ~suppress_display
    imshow(montage_img)
end
end

