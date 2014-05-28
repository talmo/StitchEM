function section = render_preview(sec, scale, alignment, R_out)
%RENDER_PREVIEW Renders a section at lower scale for previewing.

render_time = tic;

% Adjust the transforms to scale
pre_scale = make_tform('scale', 1/scale);
post_scale = make_tform('scale', scale);
tforms = compose_tforms(pre_scale, ...
                        sec.alignments.(alignment).tforms, ...
                        post_scale);

% Calculate scaled spatial refs for tiles
initial_Rs = cellfun(@(sz) imref2d(sz * scale), sec.tile_sizes, 'UniformOutput', false);
tile_Rs = cellfun(@tform_spatial_ref, initial_Rs, tforms, 'UniformOutput', false);

% Adjust output spatial ref for scale
R_out = tform_spatial_ref(R_out, post_scale);


% Transform tiles
sec_num = sec.num;
wafer_path = waferpath;
tiles = cell(sec.num_tiles, 1);
parfor t = 1:sec.num_tiles
    % Transform tile
    tiles{t} = imwarp(imload_tile(sec_num, t, scale, wafer_path), tforms{t}, 'OutputView', tile_Rs{t});
end

% Blend tiles into section
section = zeros(R_out.ImageSize, 'uint8');
for t = 1:sec.num_tiles
    % Find tile subscripts within section image
    [I, J] = R_out.worldToSubscript(tile_Rs{t}.XWorldLimits, tile_Rs{t}.YWorldLimits);

    % Blend into section
    section(I(1):I(2)-1, J(1):J(2)-1) = max(section(I(1):I(2)-1, J(1):J(2)-1), tiles{t});
    tiles{t} = [];
end

fprintf('Rendered %s (''%s'') at %sx . [%.2fs]\n', sec.name, alignment, num2str(scale), toc(render_time))


end

