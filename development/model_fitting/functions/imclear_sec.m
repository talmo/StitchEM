function sec = imclear_sec(sec, varargin)
%IMCLEAR_SEC Removes images from a section structure.
% Usage:
%   sec = imclear_sec(sec) % removes all images
%   sec = imclear_sec(sec, 'overview')
%   sec = imclear_sec(sec, 'tiles') % removes all tile sets
%   sec = imclear_sec(sec, 'tile_set1', ..., 'tile_setN')

% Overview
has_overview = isfield(sec, 'overview') && isfield(sec.overview, 'img') && ~isempty(sec.overview.img);
remove_overview = (isempty(varargin) || instr('overview', varargin));
if has_overview && remove_overview
    sec.overview.img = [];
end

% Tiles
if isfield(sec, 'tiles')
    if isempty(varargin) || instr('tiles', varargin)
        % Remove all tile sets
        tile_fields = fieldnames(sec.tiles);
    else
        % Remove just tile sets specified
        valid_tilesets = instr(varargin, fieldnames(sec.tiles), 'a');
        tile_fields = varargin(valid_tilesets);
    end
    
    sec.tiles = rmfield(sec.tiles, tile_fields);
end

end

