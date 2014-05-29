%% Initial
sec = wafers{end}{end};
[full, full_R] = render_section(sec, 'stack_z'); % render at full res

%% imresize vs imwarp
for scale = linspace(0.01, 1, 10)
    tform = make_tform('scale', scale);
    
    fprintf('<strong>Scale: %sx</strong>\n', num2str(scale))

    tic; A = imresize(full, scale); fprintf('imresize: %fs | size = [%d, %d]\n', toc, size(A))
    tic; B = imwarp(full, tform); fprintf('imwarp: %fs | size = [%d, %d]\n', toc, size(B))
end
% => imresize is much faster
% => both produce images of the same size == ceil(size(A) .* scale)
% => imresize uses bicubic interpolation with antialiasing by default
% => imwarp uses linear interpolation by default

%% Resize
scale = 0.1; tform = make_tform('scale', scale);
A = imresize(full, scale);
[B, RB] = imwarp(full, full_R, tform);

%% How should we handle the spatial ref?
% Messes up resolution:
RA1 = imref2d(size(A), full_R.XWorldLimits * scale, full_R.XWorldLimits * scale);

% Keeps resolution at 1.0 using nudge:
RA2 = tform_spatial_ref(full_R, tform);

% Same world coordinates but scaled resolution:
RA3 = imref2d(size(A), full_R.XWorldLimits, full_R.YWorldLimits);
