function features = find_features(sec, parameters)
%FIND_FEATURES Finds and saves features for a given section.
import processing.find_features

%% Parameters
% Default parameters
params.overwrite = false;

% See processing.find_features() for more info on what these do

% We use a higher metric threshold for XY features since they're detected
% at full resolution (more image data = more features)
params.xy.find_features = true;
params.xy.detector_params.method = 'surf';
params.xy.detector_params.surf.MetricThreshold = 10000;
params.xy.detector_params.surf.NumOctave = 3;
params.xy.detector_params.surf.NumScaleLevels = 4;
params.xy.detector_params.surf.SURFSize = 64;

% We use a lower metric threshold for Z features since they're resized down
% to the scaling resolution (less image data = less features)
params.z.find_features = true;
params.z.scaling_resolution = 2000;
params.z.detector_params.method = 'surf';
params.z.detector_params.surf.MetricThreshold = 5000;
params.z.detector_params.surf.NumOctave = 3;
params.z.detector_params.surf.NumScaleLevels = 4;
params.z.detector_params.surf.SURFSize = 64;

% Overwrite parameters with the ones passed in
if ~isempty(fieldnames(parameters))
    params = parameters;
end

%% Check for cached file and initialize features structure
% Initialize empty features structure
features(sec.num_tiles).xy = [];
features(sec.num_tiles).z = [];

% Load from cached file
if exist(sec.xy_features_path, 'file') && exist(sec.z_features_path, 'file') && ~params.overwrite
    features = load_features(section);
    return
end

%% Find features in each tile
% Slice out tiles sub-structure for better parallelization
tiles = sec.tiles;

% Parallelize feature detection on a per-tile basis
parfor i = 1:sec.num_tiles
    tile = tiles(i);
    tile_img = NaN;
    
    % Find XY features
    if params.xy.find_features
        % Each seam is a field of tile.seams
        seam_names = fieldnames(tile.seams);
        
        % Loop through the seams for the tile
        for seam_name_cell = seam_names'
            seam_name = seam_name_cell{1};
            
            % Check if we already had XY features from the cache
            if isfield(features(i).xy, seam_name) && ~params.overwrite
                continue % skip this seam
            end
            
            % Load tile image if it wasn't already loaded
            if isnan(tile_img)
                tile_img = imread(tile.path);
            end
            
            % Find features in relevant region
            [pts, desc] = processing.find_features( ...
                tile_img, ...
                tile.seams.(seam_name).region, ...
                params.xy.detector_params);
            
            % Save to features structure
            features(i).xy.(seam_name).descriptors = desc;
            features(i).xy.(seam_name).points = pts;
            features(i).xy.(seam_name).params = params.xy.detector_params;
            features(i).xy.(seam_name).timestamp = datestr(now);
        end
    end
    
    % Find Z features
    if params.z.find_features
        % Check if we already had Z features from the cache
        if isfield(features(i).z, 'points') && ~params.overwrite
            continue
        end
        
        % Tiles should be square
        scaling_factor = params.z.scaling_resolution / tile.width;
        
        % If tile image was already loaded, just resize it
        if ~isnan(tile_img)
            tile_img_resized = imresize(tile_img, scaling_factor);
        % Otherwise load it from disk and resize it
        else
        	tile_img_resized = imresize(imread(tile.path), scaling_factor);
        end
        
        % We want to look for features in the entire image
        whole_image = struct();
        whole_image.top = 1; whole_image.left = 1;
        whole_image.height = size(tile_img_resized, 1);
        whole_image.width = size(tile_img_resized, 2);
        
        % Find features in the resized tile
        [pts, desc] = find_features(...
            tile_img_resized, ...
            whole_image, ...
            params.z.detector_params);
        
        % Rescale points to original resolution
        pts = pts * (1 / scaling_factor); % = tile.width / scaling_resolution
        
        % Save to features structure
        features(i).z.descriptors = desc;
        features(i).z.points = pts;
        features(i).z.params = params.z.detector_params;
        features(i).z.scaling_resolution = params.z.scaling_resolution;
        features(i).z.timestamp = datestr(now);
    end
end

%% Save to cache
% We have to do some shenanigans to keep the overall features structure but
% save the individual fields (xy and z) to separate files
full_feats = features;

% Save XY features
features = rmfield(features, 'z'); % Remove the Z features from each tile
save(sec.xy_features_path, 'features') % Save to file (without Z features)

% Save Z features
features = full_feats;
features = rmfield(features, 'xy');
save(sec.z_features_path, 'features')

% Logging
msg = sprintf('Saved features for %s.', sec.name);
fprintf('%s\n', msg)
stitch_log(msg, sec.data_path);

end

