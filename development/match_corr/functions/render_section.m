function [sec_img, tile_Rs] = render_section(sec, varargin)
%RENDER_SECTION Renders the tiles of a section into a single image.
% Usage:
%   [sec_img, tile_Rs] = RENDER_SECTION(sec)
%   [sec_img, tile_Rs] = RENDER_SECTION(sec, tile_imgs)
%   [sec_img, tile_Rs] = RENDER_SECTION(sec, tile_imgs, global_R)
%   [sec_img, tile_Rs] = RENDER_SECTION(sec, global_R)
%   [sec_img, tile_Rs] = RENDER_SECTION(sec, global_R, 'tforms', tforms)
%   [sec_img, tile_Rs] = RENDER_SECTION(sec, 'tforms', tforms)
%   [sec_img, tile_Rs] = RENDER_SECTION(sec, 'tforms', 'fine') % or 'rough' or 'grid'

%% Process arguments
total_time = tic;
% Deal with the tile images array so we don't have to pass it to the input parser
tiles = {};
if nargin > 1 &&  ...
        iscell(varargin{1}) && ...
        length(varargin{1}) == sec.num_tiles && ...
        all(cellfun(@(x) isa(x, 'uint8'), varargin{1}))
    tiles = varargin{1};
    varargin(1) = []; % Clear it from varargin
end

% Parse inputs
[global_R, tforms, params] = parse_inputs(varargin{:});

%% Load and resize tiles
% Load the tiles if they weren't passed in
if isempty(tiles)
    % Check if the tiles are already in the section structure first
    if sec.tile_rough_scale >= params.render_scale && ~isempty(sec.img) && ~isempty(sec.img.rough_tiles)
        tiles = sec.img.rough_tiles;
        params.tiles_prescale = sec.tile_rough_scale;
        if params.verbosity > 1; fprintf('Using preloaded rough scale tiles (%sx.\n', num2str(params.tiles_prescale)); end
        
    elseif sec.tile_z_scale >= params.render_scale && ~isempty(sec.img) && ~isempty(sec.img.z_tiles)
        tiles = sec.img.z_tiles;
        params.tiles_prescale = sec.tile_z_scale;
        if params.verbosity > 1; fprintf('Using preloaded Z scale tiles (%sx).\n', num2str(params.tiles_prescale)); end
        
    elseif sec.tile_xy_scale >= params.render_scale && ~isempty(sec.img) && ~isempty(sec.img.xy_tiles)
        tiles = sec.img.xy_tiles;
        params.tiles_prescale = sec.tile_xy_scale;
        if params.verbosity > 1; fprintf('Using preloaded XY scale tiles (%sx).\n', num2str(params.tiles_prescale)); end
        
    % Load the tiles from disk
    else
        tiles = imload_section_tiles(sec.num, params.render_scale);
        params.tiles_prescale = params.render_scale;
        if params.verbosity > 1; fprintf('Loaded tiles from disk at render scale (%sx).\n', num2str(params.tiles_prescale)); end
    end
end

% Resize tiles if needed
if params.render_scale ~= params.tiles_prescale
    parfor i = 1:length(tiles)
        tiles{i} = imresize(tiles{i}, (1 / params.tiles_prescale) * params.render_scale);
    end
    if params.verbosity > 1; fprintf('Resized tiles (%sx) to render scale (%sx).\n', num2str(params.tiles_prescale), num2str(params.render_scale)); end
end

%% Tile transforms
% Figure out which transforms to use if not passed in
if isempty(tforms) || ischar(tforms)
    % Default to using the best alignment available
    if isempty(tforms)
        if ~any(cellfun('isempty', sec.fine_tforms))
            tforms = 'fine';
        elseif ~any(cellfun('isempty', sec.rough_tforms))
            tforms = 'rough';
        else
            tforms = 'grid';
        end
    end
    
    tforms_type = tforms;
    switch tforms_type
        case 'fine'
            tforms = sec.fine_tforms;
        case 'rough'
            tforms = sec.rough_tforms;
        case 'grid'
            % Aligns tiles to grid assuming tile images are 8000x8000 at
            % full resolution with 10% overlap
            tforms = estimate_tile_grid_alignments();
    end
    
    if params.verbosity > 1; fprintf('Using %s alignment transforms to render tiles.\n', tforms_type); end
end

% Adjust alignment transforms to render scale
% Note: This assumes that the tforms are for full resolution tiles and the
%       tile images are going to be at render scale by the time the
%       transforms are applied.
render_tforms = cell(sec.num_tiles, 1);
if params.render_scale ~= 1.0
    tform_prescale = scale_tform(1 / params.render_scale); % scale to full resolution (1.0x)
    tform_rescale = scale_tform(params.render_scale); % scale back to render scale after applying tform
    for t = 1:sec.num_tiles
        render_tforms{t} = affine2d(tform_prescale.T * tforms{t}.T * tform_rescale.T);
    end
else
    % No adjustment needed if we're rendering at full resolution
    render_tforms = tforms;
end

%% Spatial references
% Calculate tile spatial reference by applying transform to tile
% initialized to the origin
tile_Rs = cell(sec.num_tiles, 1);
for t = 1:sec.num_tiles
    tile_Rs{t} = tform_spatial_ref(imref2d(size(tiles{t})), render_tforms{t});
end

% Merge the tile spatial references to get bounds for the section if needed
if isempty(global_R)
    global_R = merge_spatial_refs(tile_Rs(:));
end

% Adjust the tile spatial references to the global R
for t = 1:sec.num_tiles
    % Get section subscripts
    [secILimits, secJLimits] = global_R.worldToSubscript(tile_Rs{t}.XWorldLimits, tile_Rs{t}.YWorldLimits);
    
    % Adjust tile to stack spatial reference
    tile_R = imref2d([diff(secILimits) + 1, diff(secJLimits) + 1], global_R.PixelExtentInWorldX, global_R.PixelExtentInWorldY);
    tile_R.XWorldLimits = tile_Rs{t}.XWorldLimits;
    tile_R.YWorldLimits = tile_Rs{t}.YWorldLimits;
    
    % Save adjusted spatial reference
    tile_Rs{t} = tile_R;
end

%% Render
% Turn off warnings about nearly singular matrix
pctRunOnAll warning('off', 'MATLAB:nearlySingularMatrix')
warning('off', 'MATLAB:nearlySingularMatrix')

% Transform tiles
parfor t = 1:sec.num_tiles
    tiles{t} = imwarp(tiles{t}, render_tforms{t}, 'OutputView', tile_Rs{t});
end

% Pre-allocate section image
sec_img = zeros(global_R.ImageSize, 'uint8');

for t = 1:sec.num_tiles
    % Calculate subscripts for indexing into section
    [I, J] = global_R.worldToSubscript(tile_Rs{t}.XWorldLimits, tile_Rs{t}.YWorldLimits);
    
    % Merge tile into section image
    sec_img(I(1):I(2), J(1):J(2)) = max(sec_img(I(1):I(2), J(1):J(2)), tiles{t});
end

% Turn warnings back on
pctRunOnAll warning('on', 'MATLAB:nearlySingularMatrix')
warning('on', 'MATLAB:nearlySingularMatrix')

if params.verbosity > 0; fprintf('Rendered section %d [%.2fs].\n', sec.num, toc(total_time)); end

end

function [global_R, tforms, params] = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;

% The spatial referencing object of the "stack" (defaults to the bounds of the section)
p.addOptional('global_R', []);

% Transforms to use to align the tiles (defaults to the fine_tforms field
% of the sec structure)
p.addParameter('tforms', []);

% The scale of the tiles that were passed in, if any
p.addParameter('tiles_prescale', 1.0);

% Scale to render the section to
p.addParameter('render_scale', 1.0);

% Debugging and visualization
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
global_R = p.Results.global_R;
tforms = p.Results.tforms;
params = rmfield(p.Results, {'global_R', 'tforms'});
end