function [secA, secB, varargout] = initialize_section_pair(fixed_sec, moving_sec, varargin)
%INITIALIZE_SECTION_PAIR Loads images and pre-aligns two sections.
% Accepts section structures (from sec_struct()) or section numbers.

%% Parse inputs
% Also loads images if needed
[secA, secB, params] = parse_inputs(fixed_sec, moving_sec, varargin{:});

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
    [secA.rough_alignments, secA.grid_aligned] = rough_align_tiles(secA);
end
[secB.rough_alignments, secB.grid_aligned] = rough_align_tiles(secB);

%% Detect features at full resolution
disp('==== Detecting finer features at high resolution.')
if isempty(secA.features)
    fprintf('== Detecting features in section %d.\n', secA.num)
    secA.features = detect_section_features(secA.img.tiles, secA.rough_alignments, 'section_num', secA.num);
end

fprintf('\n== Detecting features in section %d.\n', secB.num)
secB.features = detect_section_features(secB.img.tiles, secB.rough_alignments, 'section_num', secB.num);

%% Visualize matches
if params.show_merge || params.render_merge
    % Render the section tiles
    [secA_rough, secA_rough_R] = imshow_section(secA.num, secA.rough_alignments, 'tile_imgs', secA.img.tiles, 'scale', params.visualization_scale, 'suppress_display', true);
    [secB_rough, secB_rough_R] = imshow_section(secB.num, secB.rough_alignments, 'tile_imgs', secB.img.tiles, 'scale', params.visualization_scale, 'suppress_display', true);
    [rough_merge, rough_merge_R] = imfuse(secA_rough, secA_rough_R, secB_rough, secB_rough_R);

    % Show the merged rough aligned tiles
    if params.show_merge
        figure, imshow(rough_merge, rough_merge_R), hold on
        
        % Adjust the figure
        title(sprintf('Merged sections %d and %d (rough aligned)', secA.num, secB.num))
        integer_axes(1/params.visualization_scale)
    end
    
    varargout = {rough_merge, rough_merge_R, secA_rough, secA_rough_R, secB_rough, secB_rough_R};
end
end

function [secA, secB, params] = parse_inputs(fixed_sec, moving_sec, varargin)
% Create inputParser instance
p = inputParser;

% Required parameters
p.addRequired('fixed_sec');
p.addRequired('moving_sec');

% Visualization
p.addParameter('show_merge', false);
p.addParameter('render_merge', false);
p.addParameter('visualization_scale', 0.075);

% Validate and parse input
p.parse(fixed_sec, moving_sec, varargin{:});
secA = p.Results.fixed_sec;
secB = p.Results.moving_sec;
params = rmfield(p.Results, {'fixed_sec', 'moving_sec'});

% Load images
if ~isstruct(secA)
    secA = sec_struct(secA);
end
if ~isstruct(secB)
    secB = sec_struct(secB);
end
end