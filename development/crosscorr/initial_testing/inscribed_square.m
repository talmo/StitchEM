theta = -5;
tform = make_tform('rotate', theta);

% Bounding box of 100x100 image
sz = [100, 100];
A = bsxadd(sz2bb(sz), [-0.5, -0.5]); % blue

% Actual limits of the rotated image content
A_rot = tform.transformPointsForward(A); % blue

% Bounding box of output rotated image
A_rot_aabb = tform_bb2bb(A, tform); % magenta


%% Visualize
figure
draw_poly(A_rot_aabb, 'm0.1')
draw_poly(A_rot, 'b0.3')
axis ij equal

%% Inscribed circle
r = min(sz) / 2;
center = [sz(2) / 2 + min(A(:,1)), sz(1) / 2 + min(A(:,2))];

circle = poly_circle(r, center); % cyan

%% Visualize
figure
draw_poly(A, 'b0.3')
draw_circle(circle, 'c0.5')
axis ij equal

%% Rotate circle
circle_rot = tform.transformPointsForward(circle); % cyan

%% Visualize
figure
draw_poly(A_rot_aabb, 'm0.1')
draw_poly(A_rot, 'b0.3')
draw_circle(circle_rot, 'c0.5')

axis ij equal

%% Find square inscribed in circle
sq = squareincircle(r, center); % green

%% Visualize
figure
draw_poly(A, 'b0.3')
draw_circle(circle, 'c0.5')
draw_poly(sq, 'g0.7')
axis ij equal

%% Rotate inscribed square
sq_rot = tform.transformPointsForward(sq);

%% Visualize
figure
draw_poly(A_rot, 'b0.3')
draw_circle(circle_rot, 'c0.5')
draw_poly(sq_rot, 'g0.7')
axis ij equal

%% Rotate inscribed square back to axis-alignment
center_rot = tform.transformPointsForward(center);
sq_rot_axis = squareincircle(r, center_rot);

%% Visualize
figure
draw_poly(A_rot, 'b0.3')
draw_circle(circle_rot, 'c0.5')
draw_poly(sq_rot_axis, 'g0.7')
axis ij equal

%% Alternative inscribed square
X = unique(sort(A_rot(:,1))); Y = unique(sort(A_rot(:,2)));
r_in = min(X(end-1) - X(2), Y(end-1) - Y(2)) / 2;
sq_in = squareincircle(r_in, center_rot);

%% Visualize
figure
draw_poly(A_rot, 'b0.3')
draw_circle(circle_rot, 'c0.5')
draw_poly(sq_in, 'g0.7')
axis ij equal


%% Works!!! If the image is centered at the origin....
figure, axis equal ij
% -90 -> 0 works, except 45
for theta = 0:5:360
    %theta = -15;
    tform = make_tform('rotate', theta);

    % Bounding box of 100x100 image
    sz = [100, 100];
    A = bsxadd(sz2bb(sz), [-0.5, -0.5]); % blue

    % Actual limits of the rotated image content
    A_rot = tform.transformPointsForward(A); % blue

    % Bounding box of output rotated image
    A_rot_aabb = tform_bb2bb(A, tform); % magenta

    % Inscribed rectangle
    B = rectinrotatedrect(sz(2), sz(1), theta);

    % Visualize
    cla
    %draw_poly(A, 'b0.2')
    draw_poly(A_rot, 'b0.5')
    draw_poly(B, 'r0.7')
    title(sprintf('theta = %f', theta)), hold on
    show_axes()
    pause(0.1)
end