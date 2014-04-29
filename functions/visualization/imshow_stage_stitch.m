function stage_stitch_img = imshow_stage_stitch(section_num, suppress_display)
%IMSHOW_STAGE_STITCH Shows the stage stitched image for a section.

if nargin < 2
    suppress_display = false;
end

data_path = '/data/home/talmo/EMdata/W002';
section_path = fullfile(data_path, sprintf('S2-W002_Sec%d_Montage', section_num));
stage_stitch_path = fullfile(section_path, sprintf('StageStitched_S2-W002_sec%d.tif', section_num));

stage_stitch_img = imread(stage_stitch_path);

if ~suppress_display
    imshow(stage_stitch_img)
end
end

