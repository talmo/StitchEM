function features = detect_features(sec, varargin)
%DETECT_FEATURES Detects features in a section.

% Process parameters
[params, unmatched_params] = parse_input(sec, varargin{:});

% Find closest tile images to detection scale
tile_set = '';
F = fieldnames(sec.img);
for f = F(~cellfun('isempty', regexp(F, '_tiles$')))'
    f = f{1};
    scale = sec.img.([f '_scale']);
    if scale >= params.detection_scale
        if isempty(tile_set)
            tile_set = f;
        elseif scale <= sec.img.([tile_set '_scale'])
            tile_set = f;
        end
    end
end
if isempty(tile_set)
    error('Could not find any tile sets with resolution greater than or equal to detection scale.')
end
tiles = sec.img.(tile_set);
pre_scale = sec.img.([tile_set '_scale']);

% Find overlap regions to detect features in
bounding_boxes = sec_bb(sec, params.alignment);
if instr(params.regions, {'self', 'xy'})
    % Self intersection
    [I, idx] = intersect_poly_sets(bounding_boxes);
    overlaps = arrayfun(@(t) I([idx{t, :}]), 1:sec.num_tiles, 'UniformOutput', false)';
elseif ~isempty(params.regions)
    % Intersect with specified regions
    [I, idx] = intersect_poly_sets(bounding_boxes, params.regions);
    overlaps = arrayfun(@(t) I([idx{t, :}]), 1:sec.num_tiles, 'UniformOutput', false)';
else
    % Whole tiles
    overlaps = bounding_boxes;
end

% Eliminate overlaps that are less than the minimum area
for t = 1:sec.num_tiles
    % Find the minimum area of the overlap for the tile
    min_area = params.min_overlap_area * polyarea(bounding_boxes{t}(:,1), bounding_boxes{t}(:,2));
    
    % Find overlap regions that meet the requirement
    valid_overlaps = cellfun(@(x) polyarea(x(:,1), x(:,2)) >= min_area, overlaps{t});
    
    % Save back to overlaps
    overlaps{t} = overlaps{t}(valid_overlaps);
end

% Detect features in each tile
tile_features = cell(sec.num_tiles, 1);
tforms = sec.alignments.(params.alignment).tforms;
for t = 1:sec.num_tiles
    % Convert overlap regions to local coordinates before any alignment
    local_regions = cellfun(@(x) tforms{t}.transformPointsInverse(x), overlaps{t}, 'UniformOutput', false);
    
    % Detect features in tile
    feats = detect_surf_features(tiles{t}, 'regions', local_regions, ...
        'pre_scale', pre_scale, 'detection_scale', params.detection_scale, ...
        unmatched_params);
    
    % Get global positions of features
    feats.global_points = tforms{t}.transformPointsForward(feats.local_points);
    
    % Save to container
    tile_features{t} = feats;
end

% Save to features structure
features.tiles = tile_features;
features.alignment = params.alignment;
features.meta.wafer = sec.wafer;
features.meta.section = sec.num;
features.meta.tile_set = tile_set;
features.meta.detection_scale = params.detection_scale;
features.meta.overlaps = overlaps;
features.meta.min_overlap_area = params.min_overlap_area;
features.meta.unmatched_params = unmatched_params;

end

function [params, unmatched] = parse_input(sec, varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Alignment (to get to global)
alignments = fieldnames(sec.alignments);
p.addParameter('alignment', alignments{end}, @(x) iscell(x) || (ischar(x) && validatestr(x, alignments)));

% Regions (in global coordinates)
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