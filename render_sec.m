% Configuration
s = 2;
sec = secs{s};
alignment = 'xy';
scale = 1.0;
use_stack_ref = false;

render_path = ['renders' filesep sec.name '-' alignment '.tif'];
if scale ~= 1.0
    render_path = ['renders' filesep sec.name '-' alignment '-' num2str(scale) 'x.tif'];
end

fprintf('<strong>Rendering section</strong>: %s\n', sec.name)
fprintf('<strong>Alignment</strong>: %s\n', alignment)
fprintf('<strong>Scale</strong>: %fx\n', scale)
fprintf('<strong>Using stack reference</strong>: %d\n', use_stack_ref)
fprintf('<strong>Save path</strong>: %s\n', render_path)

%% Find section spatial reference
ref_time = tic;

% Alignment transforms
tforms = sec.alignments.(alignment).tforms;

if scale ~= 1.0
    fprintf('Rescaling transforms to %sx scale.\n', num2str(scale))
    scaling = make_tform('scale', scale);
    tforms = cellfun(@(tform) compose_tforms(tform, scaling), tforms, 'UniformOutput', false);
end
    
% Get initial spatial references before alignment
initial_Rs = cellfun(@imref2d, sec.tile_sizes, 'UniformOutput', false);

% Estimate spatial references after alignment
tile_Rs = cellfun(@tform_spatial_ref, initial_Rs, tforms, 'UniformOutput', false);

% Merge all tile references to find section reference
sec_R = merge_spatial_refs(tile_Rs{:});

ref_time = toc(ref_time);
fprintf('Calculated and merged output spatial references. [%.2fs]\n', ref_time)
%% Render section
fprintf('Rendering...')
render_time = tic;

% Transform tiles
sec_num = sec.num;
wafer_path = waferpath;
tiles = cell(sec.num_tiles);
parfor t = 1:sec.num_tiles
    % Transform tile
    tiles{t} = imwarp(imload_tile(sec_num, t, 1.0, wafer_path), tforms{t}, 'OutputView', tile_Rs{t});
end

% Blend tiles into section
section = zeros(sec_R.ImageSize, 'uint8');
for t = 1:sec.num_tiles
    % Find tile subscripts within section image
    [I, J] = sec_R.worldToSubscript(tile_Rs{t}.XWorldLimits, tile_Rs{t}.YWorldLimits);

    % Blend into section
    section(I(1):I(2)-1, J(1):J(2)-1) = max(section(I(1):I(2)-1, J(1):J(2)-1), tiles{t});
    tiles{t} = [];
end
render_time = toc(render_time);
fprintf(' Done. [%.2fs]\n', render_time)

% Write to disk
fprintf('Saving to disk...'); save_time = tic;
imwrite(section, render_path);
save_time = toc(save_time);
fprintf(' Done. [%.2fs]\n', save_time)

total_time = ref_time + render_time + save_time;
fprintf('Rendered %s in %.2fs.\n', sec.name, total_time);
