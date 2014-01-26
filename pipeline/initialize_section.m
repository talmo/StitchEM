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
if exist([section_path filesep 'stitch_metadata.mat'], 'file')
    cache = load([section_path filesep 'stitch_metadata.mat'], 'section');
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
num_tiles = sum(~cellfun(@isempty, regexp({section_files.name}, tile_filename_pattern)));

% Check to see that we've at least found some tiles
if num_tiles <= 0
    error('Couldn\''t find any tile images in the section folder.\n%s\n', section_path)
end
tiles = section_files(~cellfun(@isempty, regexp({section_files.name}, tile_filename_pattern)));

%% General metadata about the section
section.path = section_path;
section.num_tiles = num_tiles;
section.time_stamp = datestr(now);
[~, section.name] = fileparts(section_path);
section.overlap_ratio = overlap_ratio;

% Extract wafer and section numbers from the folder name
path_tokens = regexp(section_path, 'W(?<wafer>[0-9]*)_Sec(?<sec>[0-9]*)_', 'names');
section.wafer = path_tokens.wafer;
section.section_number = path_tokens.sec;

%% Metadata for each tile
% Initialize field
section.tiles = struct();

% Get basic metadata for each tile
for i = 1:num_tiles
    %tile = struct(); % Initialize empty tile structure
    tile_file = tiles(i); % Current tile file
    img_info = imfinfo([section_path filesep tile_file.name]); % Image info for tile
    filename_tokens = regexp(tile_file.name, tile_filename_pattern, 'names'); % Parse filename for row/col
    
    % Metadata
    [~, section.tiles(i).name] = fileparts(tile_file.name);
    section.tiles(i).tile_num = i;
    section.tiles(i).path = [section_path filesep tile_file.name];
    section.tiles(i).filesize = tile_file.bytes;
    section.tiles(i).width = img_info(1).Width;
    section.tiles(i).height = img_info(1).Height;
    section.tiles(i).section = section.section_number; % for convenience
    section.tiles(i).row = str2double(filename_tokens.row);
    section.tiles(i).col = str2double(filename_tokens.col);
    section.tiles(i).x_offset = (section.tiles(i).col - 1) * section.tiles(i).width * (1 - section.overlap_ratio);
    section.tiles(i).y_offset = (section.tiles(i).row - 1) * section.tiles(i).height * (1 - section.overlap_ratio);
end

% Figure out seams for each tile
for i = 1:num_tiles
    % Initialize field
    section.tiles(i).seams = struct();
    
    % Get the tile structure with the metadata we just gathered
    tile = section.tiles(i);
    
    % Figure out which seams it has
    for e = 1:num_tiles
        row = section.tiles(e).row;
        col = section.tiles(e).col;
        
        % Check if the tile is 1 grid coordinate position away
        if abs(tile.row - row) + abs(tile.col - col) == 1
            region = struct();
            
            % Left
            if tile.col > col
                % Calculate region
                region.top = 1;
                region.left = 1;
                region.height = tile.height;
                region.width = round(tile.width * section.overlap_ratio);
                
                % Save seam to structure
                tile.seams.left.region = region;
                tile.seams.left.matching_tile = e;
                tile.seams.left.matching_seam = 'right';
            end
            
            % Right
            if tile.col < col
                % Calculate region
                region.top = 1;
                region.left = round((1 - section.overlap_ratio) * tile.width) + 1;
                region.height = tile.height;
                region.width = round(tile.width * section.overlap_ratio);
                
                % Save seam to structure
                tile.seams.right.region = region;
                tile.seams.right.matching_tile = e;
                tile.seams.right.matching_seam = 'left';
            end
            
            % Top
            if tile.row > row
                % Calculate region
                region.top = 1;
                region.left = 1;
                region.height = round(tile.height * section.overlap_ratio);
                region.width = tile.width;
                
                % Save seam to structure
                tile.seams.top.region = region;
                tile.seams.top.matching_tile = e;
                tile.seams.top.matching_seam = 'bottom';
            end
            
            % Bottom
            if tile.row < row
                % Calculate region
                region.top = round((1 - section.overlap_ratio) * tile.width) + 1;
                region.left = 1;
                region.height = round(tile.height * section.overlap_ratio);
                region.width = tile.width;
                
                % Save seam to structure
                tile.seams.bottom.region = region;
                tile.seams.bottom.matching_tile = e;
                tile.seams.bottom.matching_seam = 'top';
            end
        end
    end
    
    % Save to section structure
    section.tiles(i) = tile;
end


%% Save the metadata to the section folder
save([section_path filesep 'stitch_metadata.mat'], 'section')
fprintf('Generated and saved metadata for %s.\n', section.name)
end

