function xy_matches = match_xy(sec, varargin)
%MATCH_XY Finds XY matches within a section.
% Usage:
%   sec.xy_matches = match_xy(sec)

% Process parameters
[features, params] = parse_input(sec, varargin{:});

if params.verbosity > 0
    fprintf('== Matching XY features in %s\n', sec.name)
	fprintf('Feature set: ''%s''.\n', params.feature_set)
end
if params.verbosity > 1
    fprintf('Filtering method: %s\n', params.filter_method)
    if strcmpi(params.filter_method, 'gmm')
        fprintf('Inlier clustering method (GMM): %s\n', params.inlier_cluster)
    end
end
total_time = tic;

% Match each tile pair
match_sets = {};
match_idx = cell(sec.num_tiles);
num_matches = 0;
for tA = 1:sec.num_tiles - 1
    % Get tile A features
    tileA_features = features.tiles{tA};
    for tB = tA + 1:sec.num_tiles
        % Look for overlap region between the tiles
        overlap_regionA = find(features.overlap_with{tA} == tB, 1);
        overlap_regionB = find(features.overlap_with{tB} == tA, 1);
        
        % Skip this tile pair if they do not overlap
        if isempty(overlap_regionA) || isempty(overlap_regionB)
            continue
        end
        
        % Get tile B features
        tileB_features = features.tiles{tB};
        
        % Get only the features in the overlap regions
        featsA = tileA_features(tileA_features.region == overlap_regionA, :);
        featsB = tileB_features(tileB_features.region == overlap_regionB, :);
        
        % Match using Nearest-Neighbor Ratio
        nnr_matches = nnr_match(featsA, featsB, 'out', 'rows', params.NNR);
        
        % Filter outliers
        switch params.filter_method
            case 'gmm'
                [inliers, outliers] = gmm_filter(nnr_matches, params.GMM);
            case 'geomedian'
                [inliers, outliers] = geomedian_filter(nnr_matches, params.geomedian.cutoff);
            otherwise
                % Keep all NNR matches as inliers
                inliers = 1:height(nnr_matches);
                outliers = [];
        end
        
        % Save inliers
        match_set.A = nnr_matches.A(inliers, params.keep_cols);
        match_set.B = nnr_matches.B(inliers, params.keep_cols);
        match_set.metric = nnr_matches.metric(inliers);
        
        % Save outliers
        if params.keep_outliers
            match_set.outliers.A = nnr_matches.A(outliers, params.keep_cols);
            match_set.outliers.B = nnr_matches.B(outliers, params.keep_cols);
            match_set.outliers.metric = nnr_matches.metric(outliers);
        end
        
        % Metadata
        match_set.tileA = tA;
        match_set.tileB = tB;
        match_set.num_matches = height(match_set.A);
        
        
        % Save matches
        match_sets{end + 1, 1} = match_set;
        match_idx{tA, tB} = length(match_sets);
        match_idx{tB, tA} = length(match_sets);
        num_matches = num_matches + match_set.num_matches;
    end
end

% Save to output structure
xy_matches.match_sets = match_sets;
xy_matches.tile_idx = match_idx;
xy_matches.feature_set = params.feature_set;
xy_matches.alignment = features.alignment;
xy_matches.num_matches = num_matches;
xy_matches.sec = sec.name;
xy_matches.match_type = 'xy';
xy_matches.params = params;

% Todo: make more like match_z:
% z_matches.meta.avg_error = avg_error;
% z_matches.meta.avg_nnr_error = avg_nnr_error;
% z_matches.meta.avg_outlier_error = avg_outlier_error;
% z_matches.meta.num_nnr_matches = height(nnr_matches.A);
% z_matches.meta.num_outliers = height(outliers.A);

if params.verbosity > 0; fprintf('Found %d matches. [%.2fs]\n', num_matches, toc(total_time)); end

end

function [features, params] = parse_input(sec, varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Feature set to use
%   Accepts string name of feature set in the sec struct or an actual
%   structure from detect_features
feature_sets = fieldnames(sec.features);
p.addOptional('feature_set', feature_sets{end}, @(x) (ischar(x) && validatestr(x, feature_sets)) || (isstruct(x) && isfield(x, 'tiles') && ~isempty(x.tiles)));

% NNR Parameters
NNR_defaults = struct();
NNR_defaults.MaxRatio = 0.6;
NNR_defaults.MatchThreshold = 1.0;
p.addParameter('NNR', NNR_defaults, @(x) isstruct(x) && all(instr(fieldnames(x), fieldnames(NNR_defaults), 'a')));
for f = fieldnames(NNR_defaults)'
    p.addParameter(f{1}, NNR_defaults.(f{1}));
end

% Filtering method
%   geomedian uses geomedian_filter()
%   gmm uses gmm_filter()
filtering_methods = {'geomedian', 'gmm', 'none'};
p.addParameter('filter_method', 'geomedian', @(x) ischar(x) && validatestr(x, filtering_methods));

% Keep outliers
%   Saves points that were filtered out to outliers field.
p.addParameter('keep_outliers', false);

% GMM Parameters
GMM_defaults = struct();
GMM_defaults.inlier_cluster = 'geomedian';
p.addParameter('GMM', GMM_defaults, @(x) isstruct(x) && all(instr(fieldnames(x), fieldnames(GMM_defaults), 'a')));
for f = fieldnames(GMM_defaults)'
    p.addParameter(f{1}, GMM_defaults.(f{1}));
end

% geomedian_filter Parameters
geomedian_defaults = struct();
geomedian_defaults.cutoff = '3x';
p.addParameter('geomedian', geomedian_defaults, @(x) isstruct(x) && all(instr(fieldnames(x), fieldnames(geomedian_defaults), 'a')));
for f = fieldnames(geomedian_defaults)'
    p.addParameter(f{1}, geomedian_defaults.(f{1}));
end

% Columns to keep for the matched features
%   Note: descriptors will use up a lot of memory!
feature_fields = {'local_points', 'global_points', 'descriptors', 'feature_scale'};
p.addParameter('keep_cols', {'local_points', 'global_points'}, @(x) (iscellstr(x) || all(instr(x, feature_fields, 'ea'))) || (ischar(x) && validatestr(x, feature_fields)));

% Verbosity
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

% Process feature set
if isstruct(params.feature_set)
    features = params.feature_set;
    params.feature_set = features.alignment;
else
    features = sec.features.(params.feature_set);
end

% Make sure keep_cols is a cell if only one col was passed in
if ~iscell(params.keep_cols)
    params.keep_cols = {params.keep_cols};
end

% Overwrite parameter structures with any explicit field names
params = overwrite_struct(params, NNR_defaults, 'NNR', p.UsingDefaults);
params = overwrite_struct(params, GMM_defaults, 'GMM', p.UsingDefaults);
params = overwrite_struct(params, geomedian_defaults, 'geomedian', p.UsingDefaults);
end