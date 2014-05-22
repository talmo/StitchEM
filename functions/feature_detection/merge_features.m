function merged_features = merge_features(tile_features, keep_tiles)
%MERGE_FEATURES Merges an array of features tables split up by tiles.
% Usage:
%   merged_features = merge_features(features.tiles)
%   features_struct = merge_features(features_struct)
%   features_struct = merge_features(features_struct, keep_tiles)
%
% Args:
%   tile_features is either a cell array of tile features or a feature set
%       structure returned by detect_features.
%   keep_tiles is a logical indicating whether to keep the tiles field if
%       the input is a features structure. Defaults to false.
%
% Returns:
%   merged_features is a single table with all the features. The column
%       'tile' is added to identify which tile each feature came from.
%   features_struct will be the same structure inputed but with a 
%       'features' field added with the merged features. The 'tiles' field
%       is removed unless keep_tiles is set to true.
%
% See also: split_features, detect_features

if nargin < 2
    keep_tiles = false;
end

% Handle structure from detect_features()
if isstruct(tile_features)
    features_struct = tile_features;
    if ~isfield(features_struct, 'tiles'); error('Features structure does not contain the field ''tiles''.'); end
    tile_features = features_struct.tiles;
end

validateattributes(tile_features, {'cell'}, {'nonempty'}, mfilename)

% Find the number of features in all tiles that have any features
nonempty_tiles = find(~areempty(tile_features));
num_tile_feats = zeros(size(tile_features));
num_tile_feats(nonempty_tiles) = arrayfun(@(t) height(tile_features{t}), nonempty_tiles);

% Merge features
merged_features = vertcat(tile_features{:});

% Add tile column
merged_features.tile = zeros(sum(num_tile_feats), 1, 'uint32'); % to save memory (2^32 = 4294967296)
cum_num = cumsum(num_tile_feats);
idx = cum_num - num_tile_feats + 1;
for t = 1:numel(cum_num)
    merged_features.tile(idx(t):cum_num(t)) = t;
end

% Return structure if it was the input
if exist('features_struct', 'var')
    features_struct.features = merged_features;
    if ~keep_tiles
        features_struct = rmfield(features_struct, 'tiles');
    end
    merged_features = features_struct;
end
end

