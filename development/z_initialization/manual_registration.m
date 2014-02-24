sec1 = imread('~/EMdata/W002/S2-W002_Sec1_Montage/StageStitched_S2-W002_sec1.tif');
sec2 = imread('~/EMdata/W002/S2-W002_Sec2_Montage/StageStitched_S2-W002_sec2.tif');
load('manual_control_points.mat')

%% Calculate affine transform based on control points
mytform = fitgeotrans(sec1_pts, sec2_pts, 'affine');
sec1_registered = imwarp(sec1, mytform);
imshowpair(sec1_registered, sec2)