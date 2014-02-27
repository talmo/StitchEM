%% Parameters
secA = 1;
secB = 2;

%% Register the section overviews and get initial transforms
% The first section is kept "fixed" relative to the second one
secA_rough_alignment = affine2d();

% Register the montage overviews to get a rough alignment between the sections
secB_rough_alignment = register_overviews(secA, secB);

%% Detect features in two sections
secA_features = detect_section_features(secA, secA_rough_alignment);
secB_features = detect_section_features(secB, secB_rough_alignment);

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
