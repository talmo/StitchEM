function [matchesA, matchesB, secA, secB, varargout] = match_section_pair(secA, secB, varargin)
%MATCH_SECTION_PAIR Finds the matches between two sections.

% Parse inputs
[secA, secB, params] = parse_inputs(secA, secB, varargin{:});

%% Register montage overviews
disp('==== Registering section overview images.')
try
    secB.overview_tform = register_overviews(secA.img.overview, secA.overview_tform, secB.img.overview);
    disp('Registered the two section overviews.')
catch
    disp('Failed to register the two section overviews. Tiles will be aligned to grid.')
end

%% Do a rough alignment on the tiles using the registered overviews
disp('==== Estimating rough tile alignments.')
if any(cellfun('isempty', secA.rough_alignments))
    secA.rough_alignments = rough_align_tiles(secA);
end
secB.rough_alignments = rough_align_tiles(secB);

%% Detect features at full resolution
disp('==== Detecting finer features at high resolution.')
if isempty(secA.features)
    fprintf('== Detecting features in section %d.\n', secA.num)
    secA.features = detect_section_features(secA.img.tiles, secA.rough_alignments, 'section_num', secA.num);
end

fprintf('\n== Detecting features in section %d.\n', secB.num)
secB.features = detect_section_features(secB.img.tiles, secB.rough_alignments, 'section_num', secB.num);

%% Match features across the two sections
disp('==== Match finer features across sections.')
[matchesA, matchesB] = match_feature_sets(secA.features, secB.features, ...
    'show_region_stats', false, 'verbosity', 0);

%% Visualize matches
if params.show_matches
    % Render the section tiles
    [secA_rough, secA_rough_R] = imshow_section(secA.num, secA.rough_alignments, 'tile_imgs', secA.img.tiles, 'method', 'max', 'scale', params.visualization_scale, 'suppress_display', true);
    [secB_rough, secB_rough_R] = imshow_section(secB.num, secB.rough_alignments, 'tile_imgs', secB.img.tiles, 'method', 'max', 'scale', params.visualization_scale, 'suppress_display', true);
    [rough_registration, rough_registration_R] = imfuse(secA_rough, secA_rough_R, secB_rough, secB_rough_R);

    % Show the merged rough aligned tiles
    figure, imshow(rough_registration, rough_registration_R), hold on

    % Show the matches
    plot_matches(matchesA.global_points, matchesB.global_points, params.visualization_scale)

    % Adjust the figure
    title(sprintf('Matches between sections %d and %d (n = %d)', secA.num, secB.num, size(matchesA, 1)))
    integer_axes(1/params.visualization_scale)
    hold off
    
    varargout = {rough_registration, rough_registration_R};
end
end

function [secA, secB, params] = parse_inputs(secA, secB, varargin)
% Create inputParser instance
p = inputParser;

% Required parameters
p.addRequired('secA');
p.addRequired('secB');

% Visualization
p.addParameter('show_matches', false);
p.addParameter('visualization_scale', 0.075);

% Validate and parse input
p.parse(secA, secB, varargin{:});
secA = p.Results.secA;
secB = p.Results.secB;
params = rmfield(p.Results, {'secA', 'secB'});
end