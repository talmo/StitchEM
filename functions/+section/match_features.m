function matches = match_features(sec, features, parameters)
%MATCH_FEATURES Finds matching pairs of features within overlapping tiles in a section.

% Load cached features if not passed in
if nargin < 2 || isempty(features)
    cache = load(sec.features_path);
    features = cache.features;
end

% Initialize match sets
for i = 1:sec.num_tiles
    seam_names = fieldnames(features(i).xy);
    
    for e = 1:length(seam_names)
        seam_name = seam_names{e};
        
        
    end
end
% Loop through seams
% Call processing.match_features()
% Save to cache

end

