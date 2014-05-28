function sec_Rs = sec_refs(sec, alignment)
%SEC_REFS Calculates the spatial references for the tiles of a section after alignment.
% Usage:
%   sec_Rs = sec_refs(sec, alignment)

tforms = sec.alignments.(alignment).tforms;

% Get initial spatial references before alignment
initial_Rs = cellfun(@imref2d, sec.tile_sizes, 'UniformOutput', false);

% Estimate spatial references after alignment
sec_Rs = cellfun(@tform_spatial_ref, initial_Rs, tforms, 'UniformOutput', false);

end

