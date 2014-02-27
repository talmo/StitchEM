function imshow_tile_features(section_num, tile_num, features, varargin)
%IMSHOW_TILE_FEATURES Shows a tile and its features.

%% Parameters
% Defaults
scale = 1.0;

% Hackish overwriting defaults for scale (see imshow_tile too)
if ~isempty(varargin)
    for i = 1:length(varargin)
        if isnumeric(varargin{i})
            scale = varargin{i};
        end
    end
end

if istable(features)
    if any(ismember(features.Properties.VariableNames, 'local_points'))
        points = features.local_points;
    else
        error('Could not find a local_points column in the features table.')
    end
else
    points = features;
end

if ~isnumeric(points) || size(points, 2) ~= 2
    error('Points must be an Nx2 numeric array of coordinates.')
end


%% Show tile with points
% Display the tile
imshow_tile(section_num, tile_num, varargin{:});

% Scale points if needed
if scale ~= 1.0
    points = transformPointsForward(scale_tform(scale), points);
end

% Plot the features
hold on
plot(points(:, 1), points(:, 2), 'rx')

end

