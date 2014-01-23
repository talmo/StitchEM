function section = initialize_section(section_path, overwrite, overlap_ratio)
%INITIALIZE_SECTION Reads in a section folder of EM images and generates
%metadata required for other parts of the pipeline. This data is also saved
%to the section folder as 'stich_data.mat'.
%
%If the overwrite argument is not set to true or is omitted from the
%function call, existing data files will not be overwritten.

%% Validate arguments
% Check if the path exists
if ~isdir(section_path)
    error('The specified section path does not exist.\n%s\n', section_path)
end
% Check if overwrite was passed as an argument
if nargin < 2
    overwrite = false;
end
% Check if overlap_ratio was passed as an argument
if nargin < 3
    overlap_ratio = 0.1;
end

%% Check for cached file
if exist([section_path filesep 'stitch_data.mat'], 'file')
    cache = load([section_path filesep 'stitch_data.mat'], 'section');
    % If we're not overwriting the data file, just load it and quit
    if ~overwrite
        section = cache.section;
        fprintf('Loaded %s metadata from cache saved on %s.\n', ...
            section.name, section.time_stamp)
        return
    end
end

%% Look for tile image files
% Look for files that follow the tile naming convention
tile_filename_pattern = 'Tile_r(?<row>[0-9]*)-c(?<col>[0-9]*)_.*.tif';
section_files = dir(section_path);
nTiles = sum(~cellfun(@isempty, regexp({section_files.name}, tile_filename_pattern)));

% Check to see that we've at least found some tiles
if nTiles <= 0
    error('Couldn\''t find any tile images in the section folder.\n%s\n', section_path)
end
tiles = section_files(~cellfun(@isempty, regexp({section_files.name}, tile_filename_pattern)));

%% General metadata about the section
section.path = section_path;
section.num_tiles = nTiles;
section.time_stamp = datestr(now);
[~, section.name] = fileparts(section_path);
section.overlap_ratio = overlap_ratio;

% Extract wafer and section numbers from the folder name
path_tokens = regexp(section_path, 'W(?<wafer>[0-9]*)_Sec(?<sec>[0-9]*)_', 'names');
section.wafer = path_tokens.wafer;
section.section_number = path_tokens.sec;

%% Metadata for each tile
% Initialize tiles sub-struct
section.tiles = struct(...
    'name', cell(1, nTiles), ...     % tile name
    'tile_num', cell(1, nTiles), ... % tile number
    'path', cell(1, nTiles), ...     % full path to the image file
    'filesize', cell(1, nTiles), ... % the size of the image in bytes
    'width', cell(1, nTiles), ...    % dimensions of the image in pixels
    'height', cell(1, nTiles), ...   % dimensions of the image in pixels
    'section', cell(1, nTiles), ...  % section the tile belongs to
    'row', cell(1, nTiles), ...      % coordinates relative to the grid
    'col', cell(1, nTiles), ...      %  tiles in the section
    'x_offset', cell(1, nTiles), ...        % pixel offsets based on the overlap
    'y_offset', cell(1, nTiles), ...        %  and position within the grid
    'spatial_ref', cell(1, nTiles), ...     % spatial reference structure (see imref2d)
    'edge_features', cell(1, nTiles), ...   % feature vector for the edges of the image
    'center_features', cell(1, nTiles), ... % feature vector for the center of the image
    'pts', cell(1, nTiles), ...       % global point matches for each seam
    'T', cell(1, nTiles), ...         % 3x3 linear transformation matrix
    'affine_tform', cell(1, nTiles)); % transformation saved as MATLAB affine2d structures

% Get or initialize metadata for each tile
for i = 1:nTiles
    tile = section.tiles(i); % Get empty tile structure
    tile_file = tiles(i); % Current tile file
    img_info = imfinfo([section_path filesep tile_file.name]); % Image info for tile
    filename_tokens = regexp(tile_file.name, tile_filename_pattern, 'names'); % Parse filename for row/col
    
    % Metadata
    [~, tile.name] = fileparts(tile_file.name);
    tile.tile_num = i;
    tile.path = [section_path filesep tile_file.name];
    tile.filesize = tile_file.bytes;
    tile.width = img_info(1).Width;
    tile.height = img_info(1).Height;
    tile.section = section.section_number; % for convenience
    tile.row = str2double(filename_tokens.row);
    tile.col = str2double(filename_tokens.col);
    tile.x_offset = (tile.col - 1) * tile.width * (1 - section.overlap_ratio);
    tile.y_offset = (tile.row - 1) * tile.height * (1 - section.overlap_ratio);
    tile.spatial_ref = imref2d([tile.height, tile.width], ...
        [tile.x_offset + 0.5, tile.x_offset + tile.width + 0.5], ... % global coordinates
        [tile.y_offset + 0.5, tile.y_offset + tile.height + 0.5]);
    tile.edge_features = [];
    tile.center_features = [];
    tile.pts = {};
    tile.T = eye(3); % initialize to identity matrix
    tile.affine_tform = affine2d(eye(3));
    
    % Save to section structure
    section.tiles(i) = tile;
end

%% Save the metadata to the section folder
save([section_path filesep 'stitch_data.mat'], 'section')
fprintf('Generated and saved metadata for %s.\n', section.name)
end

