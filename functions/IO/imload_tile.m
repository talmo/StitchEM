function tile_img = imload_tile(sec, tile_num, scale, wafer_path)
%IMLOAD_TILE Loads a tile given a section and tile number.
% Usage:
%   tile_img = imload_tile(sec, tile_num)
%   tile_img = imload_tile(sec_num, tile_num)
%   tile_img = imload_tile(sec_num, tile_num, scale)
%   tile_img = imload_tile(sec_num, tile_num, scale, wafer_path)
%
% Args:
%   sec: a section structure created by load_section()
%   sec_num: the section number
%   scale: optionally scales the tile (default = 1.0)
%   wafer_path: path to the section's wafer folder (default = waferpath())
%
% Note: If a section structure is specified, this function will load the
%   tile from the tile_paths or tile_files field if found.
%
% See also: load_section

if nargin < 3
    scale = 1.0;
end

% Get tile path from section structure
tile_path = '';
if isstruct(sec)
    sec_num = sec.num;
    if isfield(sec, 'tile_paths')
        tile_path = sec.tile_paths{tile_num};
    elseif isfield(sec, 'tile_files') && isfield(sec, 'path')
        tile_path = fullfile(sec.path, sec.tile_files{tile_num});
    end
else
    sec_num = sec;
end

% We couldn't find a path to the tile in the structure, or just the section
% number was specified, so look for the tile in the wafer path
if isempty(tile_path)
    if nargin < 4
        wafer_path = waferpath;
    end
    
    % Get tile path
    tile_path = get_tile_path(sec_num, tile_num, wafer_path);
end

% Load tile image from file
tile_img = imread(tile_path);

% Resize if needed
if scale ~= 1.0
    tile_img = imresize(tile_img, scale);
end
end

