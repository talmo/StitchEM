function sec = load_section(sec_num, varargin)
%LOAD_SECTION Creates a section structure given a section number.
% Usage:
%   sec = load_section(sec_num)
%
% Parameters:
%   'wafer_path', waferpath(): path to the section's wafer
%   'skip_tiles', []: indices of tiles to skip
%   'verbosity', 1: output level

% Parse inputs
params = parse_inputs(varargin{:});
if params.verbosity > 0; fprintf('== Loading section %d.\n', sec_num); end

% Path info
info = get_path_info(get_section_path(sec_num, params.wafer_path));

% Section information and metadata
sec.num = sec_num;
sec.name = info.name;
sec.path = info.path;
sec.wafer = info.wafer;
sec.num_tiles = info.num_tiles;
sec.rows = info.rows;
sec.cols = info.cols;
sec.grid = info.grid;
sec.tile_paths = fullfile(info.path, info.tiles);
sec.tile_sizes = cellfun(@(t) imsize(t), sec.tile_paths, 'UniformOutput', false)';

% Skip tiles
sec.skipped_tiles = params.skip_tiles;
if ~isempty(params.skip_tiles)
    keep = setdiff(1:sec.num_tiles, params.skip_tiles);
    new_idx = zeros(1:sec.num_tiles);
    new_idx(keep) = 1:length(keep);
    
    % Update fields
    sec.num_tiles = length(keep);
    sec.grid = new_idx(sec.grid);
    sec.tile_paths = sec.tile_paths(keep);
    sec.tile_sizes = sec.tile_sizes(keep);
end

% Initial alignment
tforms = repmat({affine2d()}, sec.num_tiles, 1);
sec.alignments.initial.tforms = tforms;
sec.alignments.initial.rel_tforms = tforms;
sec.alignments.initial.rel_to = 'initial';
sec.alignments.initial.meta.method = 'initial';

% Others
sec.overview.path = fullfile(info.path, info.overview);
sec.tiles = struct();

if params.verbosity > 0; fprintf('Created section structure for <strong>%s</strong>.\n', sec.name); end

end

function params = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;

% Wafer path
p.addParameter('wafer_path', '');

% Tiles to skip
p.addParameter('skip_tiles', []);

% Misc
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

if isempty(params.wafer_path)
    params.wafer_path = waferpath();
end
end
