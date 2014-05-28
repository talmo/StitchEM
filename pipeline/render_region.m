% Stack
%secs = secs(sec_nums);
alignment = 'blockcorr';

% Region to render
regionJ = [27000 28000]; % X
regionI = [23000 24000]; % Y
viz = false; % Visualize region


% Output folder
folder_name = sprintf('%s_Secs%d-%d_%s[%d,%d]', secs{1}.wafer, secs{1}.num, secs{end}.num, alignment, regionJ(1), regionI(1));
render_path = create_folder(fullfile(renderpath, folder_name));

%% Calculate spatial references
total_render_time = tic;
disp('==== <strong>Started rendering section regions</strong>.')
fprintf('Calculating output spatial reference...')

tile_Rs = cell(length(secs), 1);
for s = 1:length(secs)
    % For convenience
    sec = secs{s};
    tforms = sec.alignments.(alignment).tforms;
    
    % Get initial spatial references before alignment
    initial_Rs = cellfun(@imref2d, sec.tile_sizes, 'UniformOutput', false);
    
    % Estimate spatial references after alignment
    tile_Rs{s} = cellfun(@tform_spatial_ref, initial_Rs, tforms, 'UniformOutput', false);
end

% Merge all tile references to find stack reference
stack_R = merge_spatial_refs(vertcat(tile_Rs{:}));

% Create spatial reference for the region
[region_XLims, region_YLims] = stack_R.intrinsicToWorld(regionJ, regionI);
region_R = imref2d([diff(regionI), diff(regionJ)], region_XLims, region_YLims);

fprintf(' Done. [%.2fs]\n', toc(total_render_time))
%% Visualize region
if viz
    s = 100;
    plot_section(secs{s}, alignment)
    region_bb = ref_bb(region_R);
    draw_poly(region_bb)
end

%% Render each section
for s = 1:length(secs)
    render_time = tic;
    % Convenience
    sec = secs{s};
    tforms = sec.alignments.(alignment).tforms;
    sec_tile_Rs = tile_Rs{s};

    % Find tile subscripts within section image
    [I, J] = cellfun(@(R) stack_R.worldToSubscript(R.XWorldLimits, R.YWorldLimits), sec_tile_Rs, 'UniformOutput', false);
    
    % Transform tiles
    sec_num = sec.num;
    wafer_path = waferpath;
    tiles = cell(sec.num_tiles);
    parfor t = 1:sec.num_tiles
        % Tile subscripts within section
        tI = I{t};
        tJ = J{t};
        
        % Render only if tile is within the region bounds
        if ~isempty(intersect_lims(tI, regionI)) && ~isempty(intersect_lims(tJ, regionJ))
            % Transform tile
            tiles{t} = imwarp(imload_tile(sec_num, t, 1.0, wafer_path), tforms{t}, 'OutputView', sec_tile_Rs{t});
            %fprintf('Transforming section %d -> tile %d\n', sec_num, t)
        end
    end

    % Blend tiles into region
    region = zeros(region_R.ImageSize, 'uint8');
    for t = 1:sec.num_tiles
        % Skip if we didn't render this tile
        if isempty(tiles{t})
            continue
        end
        
        % Tile subscripts within section
        tI = I{t};
        tJ = J{t};
        
        % Intersect tile with region subscripts within section
        inI = intersect_lims(tI, regionI);
        inJ = intersect_lims(tJ, regionJ);

        % Find tile subscripts within region
        trI = inI - regionI(1) + [1 0];
        trJ = inJ - regionJ(1) + [1 0];
        
        % Find region subscripts within tile
        rtI = inI - tI(1) + [1 0];
        rtJ = inJ - tJ(1) + [1 0];
        
        % Blend tile into region
        region(trI(1):trI(2), trJ(1):trJ(2)) = max(region(trI(1):trI(2), trJ(1):trJ(2)), tiles{t}(rtI(1):rtI(2), rtJ(1):rtJ(2)));
        tiles{t} = [];
    end

    % Write to disk
    sec_filename = [sec.name '-' alignment '.tif'];
    imwrite(region, fullfile(render_path, sec_filename));
    
    fprintf('Rendered section %d (%d/%d). [%.2fs]\n', sec.num, s, length(secs), toc(render_time))
    clear region tiles sec
end
fprintf('==== <strong>Done rendering the region in %d sections. [%.2fs]</strong>\n\n', length(secs), toc(total_render_time));