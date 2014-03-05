function [rough_alignments, failed_registrations] = rough_align_tiles(sec)
fprintf('== Aligning tiles for section %d.\n', sec.num)

% Slice out variables needed in loop
sec_num = sec.num;
tiles = sec.img.scaled_tiles;
tile_scale = sec.tile_scale;
overview = sec.img.overview;
overview_tform = sec.overview_tform;

% Estimate alignments
rough_alignments = cell(sec.num_tiles, 1);
parfor tile_num = 1:sec.num_tiles
    tic;
    try
        rough_alignments{tile_num} = estimate_tile_alignment(tiles{tile_num}, overview, overview_tform, 'tile_pre_scale', tile_scale);
    catch
        fprintf('Failed to register section %d -> tile %d to its overview. [%.2fs]\n', sec_num, tile_num, toc)
        continue
    end
    fprintf('Estimated rough alignment for section %d -> tile %d. [%.2fs]\n', sec_num, tile_num, toc)
end

% Some tiles might have failed to be registered, in which case just align
% based on their grid position relative to the nearest registered tile
failed_registrations = find(cellfun('isempty', rough_alignments));
if any(failed_registrations)
    rough_alignments = estimate_tile_grid_alignments(rough_alignments);
    failed_str = strjoin(cellfun(@(x) num2str(x), num2cell(failed_registrations), 'UniformOutput', false)', ', ');
    fprintf('Aligned the following tiles by grid position: %s\n', failed_str)
end


end