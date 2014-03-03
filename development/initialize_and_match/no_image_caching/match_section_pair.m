%% Parameters
secA = 1;
secB = 2;

%% We initialize the first section as fixed
secA_rough_alignments = cell(16, 1);

for i = 1:16
    secA_rough_alignments{i} = estimate_tile_alignment(secB, secA, i, affine2d());
end

%% Estimate rough tile alignments for the moving section
secB_rough_alignments = cell(16, 1);

[secB_rough_alignments{1}, composition] = estimate_tile_alignment(secA, secB, 1);

for i = 2:16
    secB_rough_alignments{i} = estimate_tile_alignment(secA, secB, i, composition.moving);
end

%% Detect features in two sections
secA_features = detect_section_features(secA, secA_rough_alignments);
secB_features = detect_section_features(secB, secB_rough_alignments);

% Resize tile
% Detect
% Scale points up (multiply by scaling transform?)
% Append to big table with info on which tile it came from
% Table schema:
% | id | local_point | global_point | descriptor
% Global point has the initial transform applied to it

%% Match features across the two sections
% Loop through regions (e.g., tiles)
% Given a region, return the features (rows in the table) that are in it
% Match the features
% Append matches to match table
% Table schema:
% | id | secA | feature_idA | secB | feature_idB

%% Visualize matches
