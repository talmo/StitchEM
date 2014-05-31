function features = detect_features(sec, varargin)
%DETECT_FEATURES Detects features in a section.
% Usage:
%   sec.features.whole_tiles = detect_features(sec)
%   sec.features.xy = detect_features(sec, 'regions', 'xy')
%   sec.features.z = detect_features(sec, 'regions', z_overlaps, 'detection_scale', z_scale)
%
% See also: detect_surf_features

% Process parameters
[params, unmatched_params] = parse_input(sec, varargin{:});

total_time = tic;
if params.verbosity > 0; fprintf('== Detecting features in section %d at %sx scale.\n', sec.num, num2str(params.detection_scale)); end
tform_warnings('off')

% Get best tile images
tile_set = closest_tileset(sec, params.detection_scale);
assert(~isempty(tile_set), 'Could not find any tile sets at or above the specified scale.')
tiles = sec.tiles.(tile_set).img;
pre_scale = sec.tiles.(tile_set).scale;
if params.verbosity > 0; fprintf('Using tile set ''%s'' with base alignment ''%s''.\n', tile_set,  params.alignment); end

% Find overlap regions to detect features in
bounding_boxes = sec_bb(sec, params.alignment);
if ischar(params.regions) && instr(params.regions, {'self', 'xy'})
    % Self intersection
    [I, idx] = intersect_poly_sets(bounding_boxes);
    overlaps = arrayfun(@(t) I([idx{t, :}]), 1:sec.num_tiles, 'UniformOutput', false)';
    overlaps_with = arrayfun(@(t) find(~areempty(idx(t, :))), 1:sec.num_tiles, 'UniformOutput', false)';
elseif ~isempty(params.regions)
    % Intersect with specified regions
    [I, idx] = intersect_poly_sets(bounding_boxes, params.regions);
    overlaps = arrayfun(@(t) I([idx{t, :}]), 1:sec.num_tiles, 'UniformOutput', false)';
    overlaps_with = arrayfun(@(t) find(~areempty(idx(t, :))), 1:sec.num_tiles, 'UniformOutput', false)';
else
    % Whole tiles
    overlaps = bounding_boxes;
    overlaps_with = num2cell(1:sec.num_tiles)';
end

% Eliminate overlaps that are less than the minimum area
for t = 1:sec.num_tiles
    % Find the minimum area of the overlap for the tile
    min_area = params.min_overlap_area * polyarea(bounding_boxes{t}(:,1), bounding_boxes{t}(:,2));
    
    % Find overlap regions that meet the requirement
    valid_overlaps = cellfun(@(x) polyarea(x(:,1), x(:,2)) >= min_area, overlaps{t});
    
    % Save back to overlaps
    overlaps{t} = overlaps{t}(valid_overlaps);
    overlaps_with{t} = overlaps_with{t}(valid_overlaps);
end

% Detect features in each tile
tile_features = cell(sec.num_tiles, 1);
tforms = sec.alignments.(params.alignment).tforms;
num_tile_features = zeros(sec.num_tiles, 1);
parfor t = 1:sec.num_tiles
    % Transform overlap regions to the local coordinate system of the tile
    local_regions = cellfun(@(x) tforms{t}.transformPointsInverse(x), overlaps{t}, 'UniformOutput', false);
    
    % Detect features in tile
    feats = detect_surf_features(tiles{t}, 'regions', local_regions, ...
        'pre_scale', pre_scale, 'detection_scale', params.detection_scale, ...
        unmatched_params);
    
    % Get global positions of features
    feats.global_points = tforms{t}.transformPointsForward(feats.local_points);
    
    % Save to container
    tile_features{t} = feats;
    num_tile_features(t) = height(feats);
end
num_features = sum(num_tile_features);

% Save to features structure
features.tiles = tile_features;
features.alignment = params.alignment;
features.num_features = num_features;
features.num_tile_features = num_tile_features;
features.overlaps = overlaps;
features.overlap_with = overlaps_with;
features.meta.section = sec.name;
features.meta.tile_set = tile_set;
features.meta.tile_set_scale = pre_scale;
features.params = params;

features.meta.detection_scale = params.detection_scale;
features.meta.min_overlap_area = params.min_overlap_area;
features.meta.unmatched_params = unmatched_params;

if params.verbosity > 0; fprintf('Found %d features. [%.2fs]\n', num_features, toc(total_time)); end

tform_warnings('on')
end

function [params, unmatched] = parse_input(sec, varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Alignment
alignments = fieldnames(sec.alignments);
p.addParameter('alignment', alignments{end}, @(x) iscell(x) || (ischar(x) && validatestr(x, alignments)));

% Regions
p.addParameter('regions', {});
p.addParameter('min_overlap_area', 0.05);

% Detection scale
p.addParameter('detection_scale', 1.0);

% Verbosity
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;

end