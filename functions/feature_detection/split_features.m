function tile_features = split_features(merged_features, keep_merged)
%SPLIT_FEATURES Splits a single table of features into a cell array of tile features.
% Usage:
%   tile_features = split_features(merged_features)
%   features_struct = split_features(features_struct)
%   features_struct = split_features(features_struct, keep_merged)
%
% Args:
%   merged_features is either a table of tile features or a feature set
%       structure returned by detect_features.
%   keep_merged is a logical indicating whether to keep the features field
%       if the input is a features structure. Defaults to false.
%
% Returns:
%   tile_features is a cell array with each tile's features in its own 
%       cell. The column 'tile' is removed.
%   features_struct will be the same structure inputed but with a 
%       'tiles' field added with the split features. The 'features' field
%       is removed unless keep_merged is set to true.
%
% See also: merge_features, detect_features

if nargin < 2
    keep_merged = false;
end

% Handle structure from detect_features()
if isstruct(merged_features)
    features_struct = merged_features;
    if ~isfield(features_struct, 'features'); error('Features structure does not contain the field ''features''.'); end
    merged_features = features_struct.features;
end

validateattributes(merged_features, {'table'}, {'nonempty'})
if ~isfield(merged_features, 'tile'); error('Features table does not have a ''tile'' column.'); end

% Split
tile_nums = unique(merged_features.tile);
tile_features = cell(max(tile_nums), 1);
cols = setdiff(merged_features.Properties.VariableNames, 'tile');
for t = tile_nums'
    tile_features{t} = merged_features(merged_features.tile == t, cols);
end

% Return structure if it was the input
if exist('features_struct', 'var')
    features_struct.tiles = tile_features;
    if ~keep_merged
        features_struct = rmfield(features_struct, 'features');
    end
    tile_features = features_struct;
end

end

