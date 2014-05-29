function z_matches = match_z(secA, secB, varargin)
%MATCH_Z_GMM Finds Z matches between two sections and filters using GMM.
% Usage:
%   z_matches = match_z(secA, secB)
%   z_matches = match_z(secA, secB, feature_setA, feature_setB)
%   z_matches = match_z(secA, secB, featuresA, featuresB)
%   z_matches = match_z(..., 'Name', Value)
% 
% Args:
%   secA and secB must be section structures.
%   feature_setA and feature_setB must be strings identifying which
%       feature sets to use for matching. Alternatively:
%   featuresA and featuresB must be feature structures as returned by
%       detect_features.
%       Defaults to using the last feature set added to sec.features for
%       each section.
% 
% Parameters:
%   Nearest Neighbor Ratio:
%   'NNR', NNR_params: struct with the fields MaxRatio and MatchThreshold
%   'MaxRatio', 0.6: NNR Max Ratio (see matchFeatures())
%   'MatchThreshold', 1.0: NNR Match Threshold (see matchFeatures())
%   
%   Match Filtering:
%   'filter_method', 'gmm': Method of filtering out bad matches. Options
%       are 'gmm' (gmm_filter()), 'geomedian' (geomedian_filter()), or
%       'none' to return NNR matches without filtering.
%   
%   GMM Filtering:
%   'inlier_cluster', 'geomedian': 
%   
%   Others:
%   'keep_cols', {'local_points', 'global_points'}: string or cell array of
%       strings specifying which columns in the features tables to keep in
%       the match tables.
%       It is not recommended to keep the descriptors as they occupy a
%       large amount of memory.
%       Possible cols: 'local_points', 'global_points', 'descriptors', 'feature_scale'
%   'verbosity', 1: Controls amount of console output.
%
% See also: detect_features, nnr_match, gmm_filter, geomedian_filter

% Process parameters
[featuresA, featuresB, params] = parse_input(secA, secB, varargin{:});

if params.verbosity > 0
    fprintf('== Matching Z features between sections %d and %d\n', secA.num, secB.num)
	fprintf('Matching feature sets: Sec%d -> ''%s'' to Sec%d -> ''%s''.\n', secB.num, params.feature_setB, secA.num, params.feature_setA)
end
if params.verbosity > 1
    fprintf('Filtering method: %s\n', params.filter_method)
    if strcmpi(params.filter_method, 'gmm')
        fprintf('Inlier clustering method (GMM): %s\n', params.inlier_cluster)
    end
end
total_time = tic;

% Find matches between pairs of tiles using NNR
match_setsA = cell(secA.num_tiles * secB.num_tiles, 1);
match_setsB = cell(secA.num_tiles * secB.num_tiles, 1);
for tA = 1:secA.num_tiles
    % Get tile features
    tile_featsA = featuresA.tiles{tA};
    
    % Match with each tile it overlaps with in secB
    overlapping_tiles = featuresA.overlap_with{tA};
    for tB = overlapping_tiles
        % Get matching tile features
        tile_featsB = featuresB.tiles{tB};
        
        % Find the region numbers of the overlap between the two tiles
        regionA = find(featuresA.overlap_with{tA} == tB, 1);
        regionB = find(featuresB.overlap_with{tB} == tA, 1);
        
        % Skip if we don't have a matching region in either tile
        if isempty(regionA) || isempty(regionB)
            continue
        end
        
        % Get only the features in these regions
        region_featsA = tile_featsA(tile_featsA.region == regionA, :);
        region_featsB = tile_featsB(tile_featsB.region == regionB, :);
        
        % Skip if either has no features
        if isempty(region_featsA) || isempty(region_featsB)
            continue
        end
        
        % Match using Nearest-Neighbor Ratio
        match_set = nnr_match(region_featsA, region_featsB, params.NNR);
        
        % Skip if we didn't find any matches
        if isempty(match_set.A)
            continue
        end
        
        % Get table data from matched indices
        match_set.A = region_featsA(match_set.A, params.keep_cols);
        match_set.B = region_featsB(match_set.B, params.keep_cols);
        
        % Add tile column
        match_set.A.tile = repmat(tA, height(match_set.A), 1);
        match_set.B.tile = repmat(tB, height(match_set.B), 1);
        
        % Save matches (to first empty cell)
        idx = find(areempty(match_setsA), 1);
        match_setsA{idx} = match_set.A;
        match_setsB{idx} = match_set.B;
    end
end

% Clear empty cells
match_setsA(areempty(match_setsA)) = [];
match_setsB(areempty(match_setsB)) = [];

% Merge match sets into one table
nnr_matches.A = vertcat(match_setsA{:});
nnr_matches.B = vertcat(match_setsB{:});

% Filter outliers
filtering = struct(); % metadata on filtering step
try
    switch params.filter_method
        case 'gmm'
            [inliers, outliers] = gmm_filter(nnr_matches, params.GMM);
        case 'geomedian'
            [inliers, outliers] = geomedian_filter(nnr_matches, params.geomedian);
        otherwise
            % Keep all NNR matches as inliers
            inliers = 1:height(nnr_matches.A);
            outliers = [];
    end
    filtering.method = params.filter_method;
    filtering.used_fallback = false;
    filtering.exception = [];
catch ex
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
    filtering.method = params.filter_fallback;
    filtering.used_fallback = true;
    filtering.exception = ex;
end

% Extract the inliers
z_matches.A = nnr_matches.A(inliers, :);
z_matches.B = nnr_matches.B(inliers, :);

% Extract the outliers
z_outliers.A = nnr_matches.A(outliers, :);
z_outliers.B = nnr_matches.B(outliers, :);
if params.keep_outliers
    z_matches.outliers = z_outliers;
end

% Calculate error
avg_nnr_error = rownorm2(nnr_matches.B.global_points - nnr_matches.A.global_points);
avg_outlier_error = rownorm2(z_outliers.B.global_points - z_outliers.A.global_points);
avg_error = rownorm2(z_matches.B.global_points - z_matches.A.global_points);

% Add metadata
z_matches.num_matches = height(z_matches.A);
z_matches.secA = secA.name;
z_matches.secB = secB.name;
z_matches.alignmentA = featuresA.alignment;
z_matches.alignmentB = featuresB.alignment;
z_matches.match_type = 'z';
z_matches.meta.avg_error = avg_error;
z_matches.meta.avg_nnr_error = avg_nnr_error;
z_matches.meta.avg_outlier_error = avg_outlier_error;
z_matches.meta.num_nnr_matches = height(nnr_matches.A);
z_matches.meta.num_outliers = height(z_outliers.A);
z_matches.meta.method = 'auto';
z_matches.meta.filtering = filtering;
z_matches.params = params;

if params.verbosity > 0; fprintf('Found %d/%d inlier matches. Error before alignment: <strong>%fpx / match</strong>. [%.2fs]\n', ...
        z_matches.num_matches, z_matches.meta.num_nnr_matches, z_matches.meta.avg_error, toc(total_time)); end

end

function [featuresA, featuresB, params] = parse_input(secA, secB, varargin)

% Create inputParser instance
p = inputParser;

% Feature sets to use
%   Accepts string name of feature set in the sec structs or an actual
%   structure from detect_features
feature_setsA = fieldnames(secA.features); feature_setsB = fieldnames(secB.features);
p.addOptional('feature_setA', feature_setsA{end}, @(x) (ischar(x) && validatestr(x, feature_setsA)) || (isstruct(x) && isfield(x, 'tiles') && ~isempty(x.tiles)));
p.addOptional('feature_setB', feature_setsB{end}, @(x) (ischar(x) && validatestr(x, feature_setsB)) || (isstruct(x) && isfield(x, 'tiles') && ~isempty(x.tiles)));

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
p.addParameter('filter_method', 'gmm', @(x) ischar(x) && validatestr(x, filtering_methods));

% Fallback
%   Method to use if filtering fails
p.addParameter('filter_fallback', 'geomedian', @(x) ischar(x) && validatestr(x, filtering_methods));

% Keep outliers
%   Saves points that were filtered out to outliers field.
p.addParameter('keep_outliers', false);

% GMM Parameters
GMM_defaults = struct();
GMM_defaults.inlier_cluster = 'geomedian';
GMM_defaults.warning = 'error';
GMM_defaults.Replicates = 5;
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

% Process feature sets
if isstruct(params.feature_setA)
    featuresA = params.feature_setA;
    params.feature_setA = featuresA.alignment;
else
    featuresA = secA.features.(params.feature_setA);
end
if isstruct(params.feature_setB)
    featuresB = params.feature_setB;
    params.feature_setB = featuresB.alignment;
else
    featuresB = secB.features.(params.feature_setB);
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