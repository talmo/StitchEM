sec_num = 100;
tile_paths = get_tile_path(sec_num);
num_tiles = length(tile_paths);

%% Pre-allocate zeros
profile clear
profile on -memory

% Initialize stuff for parallelization
tiles = cell(num_tiles, 1);
for t = 1:num_tiles
    tiles{t} = zeros(8000, 8000, 'uint8');
end

% Load and resize tiles in parallel
parfor t = 1:num_tiles
    % Load full tile
    tile = imload_tile(sec_num, t);
    tiles{t} = tile;
end

profile off
profile viewer

clear tiles


%% blockproc test
% read the original photo into memory
origp = imread('cameraman.tif');

% create a function handle that we will apply to each block
tform = make_tform('rotate', 45);
myFun = @(block_struct) imwarp(block_struct.data, tform);

% setup block size
block_size = [64 64];

% compute the new derived photo
derp2 = blockproc(origp,block_size,myFun);
imshow(derp2);

%% imload_secton_tiles
profile clear
profile on -memory

tiles = imload_section_tiles(100, 1.0);

profile off
profile viewer

clear tiles