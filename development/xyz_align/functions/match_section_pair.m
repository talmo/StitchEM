function [matchesA, matchesB, outliersA, outliersB, varargout] = match_section_pair(secA, secB, varargin)
%MATCH_SECTION_PAIR Finds matches between a pair of initialized sections.

% Parse input
[params, unmatched_params] = parse_inputs(varargin{:});

matching_time = tic;

if params.verbosity > 0
    fprintf('== Matching Z features in sections %d and %d.\n', secA.num, secB.num)
end

% Match
[matchesA, matchesB, outliersA, outliersB] = match_feature_sets(secA.z_features, secB.z_features, ...
    'grid_aligned', {secA.grid_aligned, secB.grid_aligned}, ...
    'MatchThreshold', params.MatchThreshold, 'MaxRatio', params.MaxRatio, ...
    'filter_inliers', params.filter_inliers, unmatched_params);
num_matches = height(matchesA);

% Add match scale column
matchesA.scale = repmat(secA.tile_z_scale, num_matches, 1);
matchesB.scale = repmat(secA.tile_z_scale, num_matches, 1);

if params.verbosity > 0
    fprintf('Found %d Z matches. [%.2fs]\n', num_matches, toc(matching_time))
end

%% Visualize matches
if params.show_matches || params.show_outliers
    %disp('Rendering merged sections.')
    
    % Render the section tiles
    [secA_rough, secA_rough_R] = imshow_section(secA, 'display_scale', params.display_scale, 'suppress_display', true);
    [secB_rough, secB_rough_R] = imshow_section(secB, 'display_scale', params.display_scale, 'suppress_display', true);
    [rough_registration, rough_registration_R] = imfuse(secA_rough, secA_rough_R, secB_rough, secB_rough_R);
    
    % Return merged image
    varargout = {rough_registration, rough_registration_R};
end

if params.show_matches
    % Show the merged rough aligned tiles
    figure, imshow(rough_registration, rough_registration_R), hold on

    % Show the matches
    plot_matches(matchesA.global_points, matchesB.global_points, params.display_scale)

    % Adjust the figure
    title(sprintf('Matches between sections %d and %d (n = %d)', secA.num, secB.num, size(matchesA, 1)))
    integer_axes(1/params.display_scale)
    hold off
    
    varargout = {rough_registration, rough_registration_R};
end
if params.show_outliers
    % Show the merged rough aligned tiles
    figure, imshow(rough_registration, rough_registration_R), hold on

    % Show the outliers
    plot_matches(outliersA.global_points, outliersB.global_points, params.display_scale)
    
    % Adjust the figure
    title(sprintf('Outliers between sections %d and %d (n = %d)', secA.num, secB.num, size(outliersA, 1)))
    integer_axes(1/params.display_scale)
    hold off
    
end
end

function [params, unmatched] = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Z matching parameters
p.addParameter('MatchThreshold', 1.0);
p.addParameter('MaxRatio', 0.7);
p.addParameter('filter_inliers', true);

% Verbosity
p.addParameter('verbosity', 1);

% Visualization
p.addParameter('show_matches', false);
p.addParameter('show_outliers', false);
p.addParameter('display_scale', 0.025);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;
end