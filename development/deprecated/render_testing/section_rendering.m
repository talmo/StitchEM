%% Initial
sec = wafers{end}{end};
[full, full_R] = render_section(sec, 'stack_z'); % render at full res

%% Scale
scale = 0.1;
control = imresize(full, scale);
[test, test_R] = render_scaled(sec, 'stack_z', scale);
[test2, test2_R] = render_scaled2(sec, 'stack_z', scale);
[test3, test3_R] = render_section(sec, 'stack_z', 'scale', scale);

%% Compare spatial refs
R_scaled = tform_spatial_ref(full_R, make_tform('scale', scale));
R_lowres = imref2d(size(control), full_R.XWorldLimits, full_R.YWorldLimits);

%% Visualize
imshowpair(test, control, 'diff')