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

% Initialize match containers
inliersA = cell(sec.num_tiles ^ 2, 1); inliersB = cell(sec.num_tiles ^ 2, 1);
outliersA = cell(sec.num_tiles ^ 2, 1); outliersB = cell(sec.num_tiles ^ 2, 1);

% Match each tile pair
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
        
        % Skip if we didn't find any matches
        if isempty(nnr_matches.A)
            continue
        end
        
        % Add tile column
        nnr_matches.A.tile = repmat(tA, height(nnr_matches.A), 1);
        nnr_matches.B.tile = repmat(tB, height(nnr_matches.B), 1);
        
        % Filter outliers
        try
            switch params.filter_method
                case 'gmm'
                    [inliers, outliers] = gmm_filter(nnr_matches, params.GMM);
                case 'geomedian'
                    [inliers, outliers] = geomedian_filter(nnr_matches, params.geomedian.cutoff);
                otherwise
                    % Keep all NNR matches as inliers
                    inliers = 1:height(nnr_matches.A);
                    outliers = [];
            end
        catch
            switch params.filter_fallback
                case 'gmm'
                    [inliers, outliers] = gmm_filter(nnr_matches, params.GMM);
                case 'geomedian'
                    [inliers, outliers] = geomedian_filter(nnr_matches, params.geomedian.cutoff);
                otherwise
                    % Keep all NNR matches as inliers
                    inliers = 1:height(nnr_matches.A);
                    outliers = [];
            end
        end
        
        % Save matches (to first empty cell)
        idx = find(areempty(inliersA), 1);
        
        % Save inliers
        inliersA{idx} = nnr_matches.A(inliers, params.keep_cols);
        inliersB{idx} = nnr_matches.B(inliers, params.keep_cols);
        
        % Save outliers
        outliersA{idx} = nnr_matches.A(outliers, params.keep_cols);
        outliersB{idx} = nnr_matches.B(outliers, params.keep_cols);
    end
end

% Clear empty cells
inliersA(areempty(inliersA)) = [];   inliersB(areempty(inliersB)) = [];
outliersA(areempty(outliersA)) = []; outliersB(areempty(outliersB)) = [];

% Merge match sets into one table
xy_matches.A = vertcat(inliersA{:});
xy_matches.B = vertcat(inliersB{:});
xy_outliers.A = vertcat(outliersA{:});
xy_outliers.B = vertcat(outliersB{:});

% Same with outliers
if params.keep_outliers
    xy_matches.outliers = xy_outliers;
end

% Calculate error
[avg_outlier_error, outlier_norms] = rownorm2(xy_outliers.B.global_points - xy_outliers.A.global_points);
[avg_error, inlier_norms] = rownorm2(xy_matches.B.global_points - xy_matches.A.global_points);
avg_nnr_error = mean([outlier_norms; inlier_norms]);

% Add metadata
xy_matches.num_matches = height(xy_matches.A);
xy_matches.sec = sec.name;
xy_matches.alignment = features.alignment;
xy_matches.match_type = 'xy';
xy_matches.meta.avg_error = avg_error;
xy_matches.meta.avg_nnr_error = avg_nnr_error;
xy_matches.meta.avg_outlier_error = avg_outlier_error;
xy_matches.meta.num_outliers = height(xy_outliers.A);
xy_matches.meta.num_nnr_matches = height(xy_outliers.A) + height(xy_matches.A);
xy_matches.params = params;

if params.verbosity > 0; fprintf('Found %d/%d inlier matches. Error before alignment: <strong>%fpx / match</strong>. [%.2fs]\n', ...
        xy_matches.num_matches, xy_matches.meta.num_nnr_matches, xy_matches.meta.avg_error, toc(total_time)); end

end

function [features, params] = parse_input(sec, varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Feature set to use
%   Accepts string name of feature set in the sec struct or an actual
%   structure from detect_features
feature_sets = fieldnames(sec.features);
p.addOptional('feature_set', 'xy', @(x) (ischar(x) && validatestr(x, feature_sets)) || (isstruct(x) && isfield(x, 'tiles') && ~isempty(x.tiles)));

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

% Fallback
%   Method to use if filtering fails
p.addParameter('filter_fallback', 'none', @(x) ischar(x) && validatestr(x, filtering_methods));

% Keep outliers
%   Saves points that were filtered out to outliers field.
p.addParameter('keep_outliers', false);

% GMM Parameters
GMM_defaults = struct();
GMM_defaults.inlier_cluster = 'smallest_var';
GMM_defaults.warning = 'error';
GMM_defaults.Replicates = 5;
p.addParameter('GMM', GMM_defaults, @(x) isstruct(x) && all(instr(fieldnames(x), fieldnames(GMM_defaults), 'a')));
for f = fieldnames(GMM_defaults)'
    p.addParameter(f{1}, GMM_defaults.(f{1}));
end

% geomedian_filter Parameters
geomedian_defaults = struct();
geomedian_defaults.cutoff = '1.25x';
p.addParameter('geomedian', geomedian_defaults, @(x) isstruct(x) && all(instr(fieldnames(x), fieldnames(geomedian_defaults), 'a')));
for f = fieldnames(geomedian_defaults)'
    p.addParameter(f{1}, geomedian_defaults.(f{1}));
end

% Columns to keep for the matched features
%   Note: descriptors will use up a lot of memory!
feature_fields = {'local_points', 'global_points', 'descriptors', 'feature_scale', 'tile'};
p.addParameter('keep_cols', {'local_points', 'global_points', 'tile'}, @(x) (iscellstr(x) || all(instr(x, feature_fields, 'ea'))) || (ischar(x) && validatestr(x, feature_fields)));

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