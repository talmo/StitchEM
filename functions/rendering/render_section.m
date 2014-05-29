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
if params.verbosity > 0; fprintf('Rendering section <strong>%s</strong> (%sx).', sec.name, num2str(params.scale)); end

%% Alignment
if ischar(alignment)
    alignment = validatestring(alignment, fieldnames(sec.alignments), mfilename);
    tforms = sec.alignments.(alignment).tforms;
elseif isstruct(alignment)
    assert(isfield(alignment, 'tforms'))
    tforms = alignment.tforms;
elseif iscell(alignment)
    assert(all(cellfun(@(t) isa(t, 'affine2d'), alignment)))
    tforms = alignment;
end
assert(numel(tforms) == sec.num_tiles)

if params.verbosity > 0; fprintf('.'); end

%% Render section
% Figure out tile paths
if isfield(sec, 'tile_paths')
    tile_paths = sec.tile_paths;
elseif isfield(sec, 'tile_files') && isfield(sec, 'path')
    tile_paths = fullfile(sec.path, sec.tile_files);
end

% Load and transform tiles
tiles = cell(sec.num_tiles, 1);
sizes = sec.tile_sizes;
Rs = cell(sec.num_tiles, 1);
parfor t = 1:sec.num_tiles
    % Load and resize if needed
    tile = imread(tile_paths{t});
    if params.scale ~= 1.0; tile = imresize(tile, params.scale); end
    
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
for t = 1:sec.num_tiles
    % Find tile subscripts within section image
    [I, J] = ref2subs(Rs{t}, section_R);
    
    % Blend into section
    section(I(1):I(2), J(1):J(2)) = max(section(I(1):I(2), J(1):J(2)), tiles{t});
    tiles{t} = [];
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
