function imshow_tile_features(tile_img, features, varargin)
%IMSHOW_TILE_FEATURES Shows a tile and its features.
% Usage:
%   IMSHOW_TILE_FEATURES(tile_img, local_points)
%   IMSHOW_TILE_FEATURES(tile_img, features) % will plot local_points
%   IMSHOW_TILE_FEATURES(..., 'Name', Value)
%
% Name-Value Pairs:
%   display_scale (default = 0.25): Scale to display the tile and points in
%   pre_scale (default = 1.0): Scale the inputed tile image is in

% TODO:
%   IMSHOW_TILE_FEATURES(sec_num, tile_num, local_points)
%   IMSHOW_TILE_FEATURES(sec_struct, tile_num, local_points)
%   IMSHOW_TILE_FEATURES(sec_num, tile_num, local_points)
%   IMSHOW_TILE_FEATURES(sec_num, tile_num, features) % will plot local_points

% Parse parameters
[tile_img, points, params] = parse_inputs(tile_img, features, varargin{:});

% Resize the tile if needed
if params.pre_scale ~= params.display_scale
    tile_img = imresize(tile_img, params.pre_scale * params.display_scale);
end

% Display the tile
imshow(tile_img), hold on

% Plot points
plot_features(points, params.display_scale);

% Adjust plot
title(sprintf('Tile features (n = %d)', size(points, 1)))
integer_axes(1/params.display_scale);
hold off
end

function [tile_img, points, params] = parse_inputs(tile_img, features, varargin)
% Create inputParser instance
p = inputParser;

% Required parameters
p.addRequired('tile_img');
p.addRequired('features');

% Scaling
p.addParameter('display_scale', 0.25);
p.addParameter('pre_scale', 1.0);

% Validate and parse input
p.parse(tile_img, features, varargin{:});
tile_img = p.Results.tile_img;
features = p.Results.features;
params = rmfield(p.Results, {'tile_img', 'features'});

% Pull out local features if needed
if istable(features)
    points = features.local_points;
else
    points = features;
end
end