function [secA, secB, varargout] = initialize_section_pair(fixed_sec, moving_sec, varargin)
%INITIALIZE_SECTION_PAIR Loads images and pre-aligns two sections.
% Accepts section structures (from sec_struct()) or section numbers.

%% Parse inputs
% Also loads images if needed
[secA, secB, params, unmatched_params] = parse_inputs(fixed_sec, moving_sec, varargin{:});

%% Register montage overviews
disp('==== Registering section overview images.')
if all(all(secB.overview_tform.T == affine2d().T)) || params.overwrite_overview_registration
    try
        secB.overview_tform = register_overviews(secA.img.overview, secA.overview_tform, secB.img.overview);
        disp('Registered the two section overviews.')
    catch
        disp('Failed to register the two section overviews. Sections will not be aligned.')
    end
else
    disp('Sections overviews are already registered.')
end

%% Do a rough alignment on the tiles using the registered overviews
disp('==== Estimating rough tile alignments.')

if any(cellfun('isempty', secA.rough_alignments)) || params.overwrite_rough_alignments
    [secA.rough_alignments, secA.grid_aligned] = rough_align_tiles(secA);
else
    fprintf('Section %d is already roughly aligned.\n', secA.num)
end
if any(cellfun('isempty', secB.rough_alignments)) || params.overwrite_rough_alignments
    [secB.rough_alignments, secB.grid_aligned] = rough_align_tiles(secB);
else
    fprintf('Section %d is already roughly aligned.\n', secB.num)
end

%% Detect features at full resolution
disp('==== Detecting finer features at high resolution.')
if isempty(secA.features) || params.overwrite_features
    fprintf('== Detecting features in section %d.\n', secA.num)
    secA.features = detect_section_features(secA.img.tiles, secA.rough_alignments, 'section_num', secA.num, unmatched_params);
else
    fprintf('Section %d already has features detected.\n', secA.num)
end

if isempty(secB.features) || params.overwrite_features
    fprintf('== Detecting features in section %d.\n', secB.num)
    secB.features = detect_section_features(secB.img.tiles, secB.rough_alignments, 'section_num', secB.num, unmatched_params);
else
    fprintf('Section %d already has features detected.\n', secB.num)
end

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

function [secA, secB, params, unmatched] = parse_inputs(fixed_sec, moving_sec, varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Required parameters
p.addRequired('fixed_sec');
p.addRequired('moving_sec');

% Overwrites
p.addParameter('overwrite_overview_registration', false);
p.addParameter('overwrite_rough_alignments', false);
p.addParameter('overwrite_features', false);

% Visualization
p.addParameter('show_merge', false);
p.addParameter('render_merge', false);
p.addParameter('visualization_scale', 0.075);

% Tile scaling (if it will be loaded)
p.addParameter('tile_resize_scale', 0.25); % ideally this should be the feature detection scale so we don't have to resize again

% Validate and parse input
p.parse(fixed_sec, moving_sec, varargin{:});
secA = p.Results.fixed_sec;
secB = p.Results.moving_sec;
params = rmfield(p.Results, {'fixed_sec', 'moving_sec'});
unmatched = p.Unmatched;

% Load images
if ~isstruct(secA)
    secA = sec_struct(secA, params.tile_resize_scale);
end
if ~isstruct(secB)
    secB = sec_struct(secB, params.tile_resize_scale);
end
end