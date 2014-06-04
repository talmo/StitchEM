function [section, section_R] = render_section(sec, alignment, varargin)
%RENDER_SECTION Renders a section after applying alignment transforms.
% Usage:
%   section = render_section(sec, tforms)
%   section = render_section(sec, alignment)
%   section = render_section(sec, alignment_struct)
%   section = render_section(sec, __, stack_R)
%   [section, R] = render_section(sec, __)
%   __ = render_section(sec, ..., 'Name', Value)
%
% Parameters:
%   'scale', 1.0: scale to render the section in
%   'verbosity', 1: controls output
%
% Note: The returned R is the same as stack_R if it was specified.

% Parse parameters
params = parse_inputs(varargin{:});
total_time = tic;

% Validate alignment and get transforms
[alignment, alignment_name] = validatealignment(alignment, sec);
tforms = alignment.tforms;

if params.verbosity > 0; fprintf('Rendering section <strong>%s</strong> (%sx | %s).', sec.name, num2str(params.scale), alignment_name); end

% Figure out tile paths
if isfield(sec, 'tile_paths')
    tile_paths = sec.tile_paths;
elseif isfield(sec, 'tile_files') && isfield(sec, 'path')
    tile_paths = fullfile(sec.path, sec.tile_files);
end

% Initialize
tiles = cell(sec.num_tiles, 1);
sizes = sec.tile_sizes;
Rs = cell(sec.num_tiles, 1);

% Use pre-loaded tiles if available
pre_scale = 1.0;
if ~isempty(sec.tiles)
    tile_set = closest_tileset(sec, params.scale);
    if ~isempty(tile_set)
        tiles = sec.tiles.(tile_set).img;
        pre_scale = sec.tiles.(tile_set).scale;
    end
end

% Transform tiles
parfor t = 1:sec.num_tiles
    % Tile
    tile = tiles{t};
    scale = params.scale / pre_scale;
    if isempty(tiles{t})
        % Load tile if we don't already have it
        tile = imread(tile_paths{t});
        scale = params.scale;
    end
    
    % Resize (if needed)
    if params.scale ~= 1.0; tile = imresize(tile, scale); end
    
    % Adjust spatial ref for resolution
    [XLims, YLims] = sz2lims(sizes{t});
    R = imref2d(size(tile), XLims, YLims);
    
    % Transform
    [tiles{t}, Rs{t}] = imwarp(tile, R, tforms{t});
end
if params.verbosity > 0; fprintf('.'); end

% Figure out spatial reference for output image
section_R = params.stack_R;
if isempty(section_R)
    section_R = merge_spatial_refs(Rs);
end

% Blend tiles into section
section = zeros(section_R.ImageSize, 'uint8');
halfway = floor(median(1,sec.num_tiles));
for t = 1:sec.num_tiles
    % Find tile subscripts within section image
    [I, J] = ref2subs(Rs{t}, section_R);
    
    % Blend into section
    section(I(1):I(2), J(1):J(2)) = max(section(I(1):I(2), J(1):J(2)), tiles{t});
    tiles{t} = [];
    if params.verbosity > 0 && t == halfway; fprintf('.'); end
end

if params.verbosity > 0; fprintf(' Done. [%.2fs]\n', toc(total_time)); end

end

function params = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;

% Stack reference
p.addOptional('stack_R', [], @(x) isa(x, 'imref2d'));

% Scaling
p.addParameter('scale', 1.0);

% Verbosity
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
end
