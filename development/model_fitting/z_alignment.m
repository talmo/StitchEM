%% Initialize
% Get sections that are XY aligned
secA = get_aligned_sec(102);
secB = get_aligned_sec(103);

% Register overviews
overview_tform = register_overviews(secB, secA);

% Adjust tforms to the overview alignment

%% Detect features
secA = detect_section_features(secA, 'z');
secB = detect_section_features(secB, 'z');

% Adjust features to XY alignment
for t = 1:secA.num_tiles
    idx = secA.z_features.tile == t;
    secA.z_features.global_points(idx, :) = secA.xy_tforms{t}.transformPointsForward(secA.z_features.local_points(idx, :));
end
for t = 1:secB.num_tiles
    idx = secB.z_features.tile == t;
    secB.z_features.global_points(idx, :) = secB.xy_tforms{t}.transformPointsForward(secB.z_features.local_points(idx, :));
end

% TODO: write a function that takes this syntax:
%   - Use detect_section_features as a base
%   - Resizes from full size to detection scale (maybe let
%   detect_tile_features do this?)
%   - Applies base transform to the tile bounding boxes to find where each
%   tile intersects with regions array to see where each features should be
%   detected in each tile
%   - The base tform is usually the rough tform, but could also be the xy
%   tform for instance
%featuresA = detect_features(secA, 'detection_scale', 0.125, 'regions', regions);
%featuresB = detect_features(secB, 'detection_scale', 0.125, 'regions', regions);



%% Match
% Match using NNR
[z_matches.A, z_matches.B] = match_section_pair(secA, secB, 'filter_inliers', false);

%% Analysis
% Calculate displacements
displacements = z_matches.B.global_points - z_matches.A.global_points;

% Scatter plot with geometric median
plot_displacements(displacements)

% Calculate the distance from the median
M = geomedian(displacements);
delta_from_M = addvec(displacements, -M);
[~, norms] = rownorm2(delta_from_M);

% Distance from median
figure, hist(norms, 20), title('Distances from median')
xlabel('Euclidean Distances (px)'), ylabel('Frequency')

% - Maybe cluster by distance to geometric median for first-pass outlier
% filtering?

%% 

%% Align
% - Try using sparse least squares solver
% - Try using CPD

%% CPD
fixed = z_matches.A.global_points;
moving = z_matches.B.global_points;

opt.method = 'affine';
opt.corresp = 1;
[Transform, C] = cpd_register(fixed, moving, opt);

% Initial point-sets
%figure,cpd_plot_iter(fixed, moving); title('Before');

% Registered point-sets
%figure,cpd_plot_iter(fixed, Transform.Y);  title('After');

