function [stack_R, sec_Rs] = stack_ref(secs, alignment)
%STACK_REF Returns a set of spatial referencing objects common to the entire stack.
% Usage:
%   [stack_R, sec_Rs] = stack_ref(secs, alignment)

sec_Rs = cell(length(secs), 1);
for s = 1:length(secs)
    % For convenience
    sec = secs{s};
    tforms = sec.alignments.(alignment).tforms;
    
    % Get initial spatial references before alignment
    initial_Rs = cellfun(@imref2d, sec.tile_sizes, 'UniformOutput', false);
    
    % Estimate spatial references after alignment
    sec_Rs{s} = cellfun(@tform_spatial_ref, initial_Rs, tforms, 'UniformOutput', false);
end

% Merge all tile references to find stack reference
stack_R = merge_spatial_refs(vertcat(sec_Rs{:}));

end

