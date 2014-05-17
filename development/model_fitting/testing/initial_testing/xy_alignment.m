%% Initialization
% Load images and such
sec = load_sec(101, 'from_cache', false);

%% Rough alignment
% Register the tiles to their overviews
sec = rough_align_tiles(sec);

%% Detect features
% Get overlap regions
% find_overlaps(secA, secB) % z overlaps
% find_overlaps(secA, secA) % xy overlaps

% Detect features in regions
% detect_section_features(sec, regions, scale) % will detect features at the given scale, in any parts of the tiles that overlap with the input regions

sec = detect_section_features(sec, 'xy');

%% Match XY features
[matches.A, matches.B] = match_section_features(sec);

%% Solve XY alignment
tic;
% Build sparse matrices
[A, B] = matchmat(matches.A, matches.B);
% AT = BT
% (B - A)T = 0
% CT = 0
C = B - A;

% Deal with fixed tile
fixed_tile = 1;

% DT = F
j = 3 * fixed_tile - 2:3 * fixed_tile; % columns of fixed tile
F = -C(:, j); % fixed tile block column
D = C(:, setdiff(1:size(C, 2), j)); % C without F

toc

tic;
% Solve
T = D \ F;

% Format into cell array of affine2d objects
Ts = mat2cell(full(T(:, 1:2)), repmat(3, length(T) / 3, 1));
rel_tforms = [{affine2d()}; cellfun(@(t) affine2d(t), Ts, 'UniformOutput', false)];

% Compose with rough tforms
tforms = cellfun(@(t1, t2) compose_tforms(t1, t2), sec.rough_tforms, rel_tforms, 'UniformOutput', false);

% Calculate residuals and show average error
res = full(D * T - F);
fprintf('Error: %fpx / match [%.2fs]\n', rownorm2(res(:, 1:2)), toc)
return

%% Visualize result
imshow_section(sec, 'tforms', tforms)

%% Compare to Tikhonov
%lambda_curve(matches.A, matches.B)
lambda = 0.02;
tik_rel_tforms = tikhonov_sparse(matches.A, matches.B, 'lambda', lambda);
tik_tforms = cellfun(@(t1, t2) compose_tforms(t1, t2), sec.rough_tforms, tik_rel_tforms', 'UniformOutput', false);
%imshow_section(sec, 'tforms', tik_tforms)

%% Render results
imwrite(render_section(sec, 'tforms', tforms), [sec.name '-Tile' num2str(fixed_tile) '-Fixed.tif'])
imwrite(render_section(sec, 'tforms', tik_tforms), [sec.name '-Tikhonov.tif'])



%% Outliers
% Calculate displacements
displacements = matches.A.global_points - matches.B.global_points;

% Find the geometric median of the displacements
M = geomedian(displacements);

% Plot
scatter(displacements(:,1), displacements(:,2), 'ko')
hold on, grid on
plot(M(1), M(2), 'r*')