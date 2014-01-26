function features = find_section_features(section, parameters)
%FIND_SECTION_FEATURES Finds and saves features for a given section.
% Takes a section structure returned from initialize_section()

%% Parameters
% Default parameters
params.overwrite = false;

params.xy.find_features = true;
params.xy.detector_params.method = 'surf';
params.xy.detector_params.surf.MetricThreshold = 10000;
params.xy.detector_params.surf.NumOctave = 3;
params.xy.detector_params.surf.NumScaleLevels = 4;
params.xy.detector_params.surf.SURFSize = 64;

params.z.find_features = true;
params.z.scaling_resolution = 2000;
params.z.detector_params.method = 'surf';
params.z.detector_params.surf.MetricThreshold = 5000;
params.z.detector_params.surf.NumOctave = 3;
params.z.detector_params.surf.NumScaleLevels = 4;
params.z.detector_params.surf.SURFSize = 64;

% Overwrite defaults with any parameters passed in
% if nargin >= 2
%     f = fieldnames(parameters); % fields
%     for i = 1:length(f)
%         sf = fieldnames(parameters.(f{i})); % subfields
%         for e = 1:length(sf)
%             params.(f{i}).(sf{e}) = parameters.(f{i}).(sf{e});
%         end
%     end
% end

%% Check for cached file and initialize features structure
features = struct();

% Load from cached file
if exist([section.path filesep 'stitch_features.mat'], 'file')
    cache = load([section.path filesep 'stitch_features.mat'], 'features');
    features = cache.features;
    if params.overwrite
        features = struct();
    end
end

% Initialize empty sub-structures if necessary
if ~isfield(features, 'xy')
     features(section.num_tiles).xy = struct();
end
if ~isfield(features, 'z')
     features(section.num_tiles).z = struct();
end

%% Find features in each tile
parfor i = 1:section.num_tiles
    tile = section.tiles(i);
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
            [pts, desc] = find_features( ...
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
save([section.path filesep 'stitch_features.mat'], 'features')
fprintf('Saved features for %s.\n', section.name)

end

