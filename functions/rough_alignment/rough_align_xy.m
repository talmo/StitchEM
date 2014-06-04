function alignment = rough_align_xy(sec, varargin)
%ROUGH_ALIGN_XY Does a rough alignment on the section based on registration to its overview.
% Usage:
%   sec.alignments.rough_xy = rough_align_xy(sec)

% Parse inputs
params = parse_input(varargin{:});

if params.verbosity > 0
    fprintf('== Rough aligning tiles for section %d.\n', sec.num)
end
total_time = tic;

%% Register to overview
registration_tforms = cell(sec.num_tiles, 1);
if params.align_to_overview
    reg_params = params.overview_registration;
    
    % Tiles
    tile_set = closest_tileset(sec, params.overview_registration.tile_scale);
    assert(~isempty(tile_set), 'Could not find any tile sets at or above the specified scale.')
    tiles = sec.tiles.(tile_set).img;
    p.tile_prescale = sec.tiles.(tile_set).scale;
    
    % Overview
    assert(~isempty(sec.overview), 'Overview is not loaded in the section.')
    overview = sec.overview.img;
    p.overview_prescale = sec.overview.scale;
    p.overview_tform = sec.overview.alignment.tform;

    % Estimate alignments
    intermediate_tforms = cell(sec.num_tiles, 1);
    tform_warnings('off');
    parfor t = 1:sec.num_tiles
        registration_time = tic;
        try
            % reg_params are the parameters specified by this function
            % p are additional parameters needed by estimate_tile_alignments
            [registration_tforms{t}, intermediate_tforms{t}] = ...
                estimate_tile_alignment(tiles{t}, overview, reg_params, p);
        catch
            if params.verbosity > 2; printf('Failed to register tile %d to overview. [%.2fs]\n', t, toc(registration_time)); end
            continue
        end
        if params.verbosity > 2; fprintf('Estimated rough alignment for section %d -> tile %d. [%.2fs]\n', tile_num, toc(registration_time)); end
    end
    tform_warnings('off');
    
    registered_tiles = find(~areempty(registration_tforms));
    if params.verbosity > 1; fprintf('Registered to overview: %s\n', vec2str(registered_tiles)); end
    
    % Metadata
    reg_meta.registered_tiles = registered_tiles;
    reg_meta.tile_set = tile_set;
    reg_meta.tile_prescale = p.tile_prescale;
    reg_meta.overview_prescale = p.overview_prescale;
    reg_meta.overview_tform = p.overview_tform;
    reg_meta.overview_rel_to_sec = sec.overview.alignment.rel_to_sec;
    reg_meta.intermediate_tforms = intermediate_tforms;
else
    if params.verbosity > 0; disp('Skipping overview registration.'); end
end

%% Grid alignment
% Align unregistered tiles to grid relative to closest registered tiles
alignment = rel_grid_alignment(sec, registration_tforms, params.rel_to, params.expected_overlap);

grid_aligned = find(areempty(registration_tforms));
if params.verbosity > 1; fprintf('Grid aligned: %s\n', vec2str(grid_aligned)); end

% Additional metadata
alignment.meta.grid_aligned = grid_aligned;
alignment.meta.method = 'rough_align_xy';
if params.align_to_overview
    alignment.meta.overview_registration = reg_meta;
end

if params.verbosity > 0; fprintf('Registered <strong>%d/%d</strong> tiles to overview. [%.2fs]\n', sec.num_tiles-length(grid_aligned), sec.num_tiles, toc(total_time)); end

end

function params = parse_input(varargin)
% Create inputParser instance
p = inputParser;

% Base alignment
p.addParameter('rel_to', 'initial');

% Overview registration
p.addParameter('align_to_overview', true);
reg_defaults.tile_scale = 0.07 * 0.78;
reg_defaults.overview_scale = 0.78;
reg_defaults.overview_crop_ratio = 0.5;
p = params_struct(p, 'overview_registration', reg_defaults);

% Grid alignment
p.addParameter('expected_overlap', 0.1)

% Debugging
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

% Overwrite parameter structures with any explicit field names
params = overwrite_struct(params, reg_defaults, 'overview_registration', p.UsingDefaults);
end