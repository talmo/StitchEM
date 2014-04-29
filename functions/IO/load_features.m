function features = load_features(sec_num, cache_path)
%LOAD_FEATURES Loads the features for a given section in the current wafer.

if nargin < 2
    cache_path = cachepath;
end

[~, sec_name] = fileparts(get_section_path(sec_num));
features_cache = fullfile(cache_path, 'features', [sec_name '.mat']);

if exist(features_cache, 'file')
    cache = load(features_cache);
    features = cache.features;
else
    error('Could not find cached features for section %d in wafer %s.\nCache path: %s', sec_num, waferpath, cache_path)
end
end

