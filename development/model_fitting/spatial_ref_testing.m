% Stack
secs = {secA, secB};
alignments = {'xy', 'z_lsq'};

% Clear any loaded images to save memory
secs = cellfun(@imclear_sec, secs, 'UniformOutput', false);

%% Figure out global limits
% Although this works, it does not take into account the adjustment for
% resolution that imwarp does (see: tform_spatial_ref).
% Consequently, the stack limits computed here will correspond to a
% resolution that isn't 1 and we'll have to recompute the individual tile
% spatial refs to match the output resolution.

% Find the  limits of each section after alignment
XLims_secs = cell(size(secs));
YLims_secs = cell(size(secs));
for s = 1:length(secs)
    % For convenience
    sec = secs{s};
    alignment = sec.alignments.(alignments{s});
    
    % Get the initial tile limits before any alignment
    [XLims_in, YLims_in] = cellfun(@sz2lims, sec.tile_sizes, 'UniformOutput', false);
    
    % Estimate the limits of each tile after alignment
    [XLims_out, YLims_out] = cellfun(@(tform, X, Y) tform.outputLimits(X, Y), alignment.tforms, XLims_in, YLims_in, 'UniformOutput', false);
    
    % Find the section limits
    X = cell2mat(XLims_out); XLims_sec = [min(X(:)), max(X(:))];
    Y = cell2mat(YLims_out); YLims_sec = [min(Y(:)), max(Y(:))];
    
    % Save
    XLims_secs{s} = XLims_sec;
    YLims_secs{s} = YLims_sec;
end

% Find the stack limits
X = cell2mat(XLims_secs); XLims_stack = [min(X(:)), max(X(:))];
Y = cell2mat(YLims_secs); YLims_stack = [min(Y(:)), max(Y(:))];



%% Figure out global limits
tile_Rs = cell(length(secs), 1);
for s = 1:length(secs)
    % For convenience
    sec = secs{s};
    alignment = sec.alignments.(alignments{s});
    
    % Get initial spatial references before alignment
    initial_Rs = cellfun(@imref2d, sec.tile_sizes, 'UniformOutput', false);
    
    % Estimate spatial references after alignment
    tile_Rs{s} = cellfun(@tform_spatial_ref, initial_Rs, alignment.tforms, 'UniformOutput', false);
end

% Merge all tile references to find stack reference
stack_R = merge_spatial_refs(vertcat(tile_Rs{:}));

%% Test
% Find the row,col indices of the world limits of each tile in the stack_R
coords = {};
for s = 1:length(secs)
    for t = 1:secs{s}.num_tiles
        [I, J] = stack_R.worldToSubscript(tile_Rs{s}{t}.XWorldLimits', tile_Rs{s}{t}.YWorldLimits');
        coords{end + 1} = [I J];
    end
end
coords = cell2mat(coords');

% The row, col indices should all be within the image
assert(all(min(coords) == [1 1]))
assert(all(max(coords) == stack_R.ImageSize))
disp('Passed assertions.')