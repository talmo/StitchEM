function plot_stack(secs, alignment, outline_only)
%PLOT_STACK Plots a 3d visualization of the stack.

if nargin < 2
    alignments = fieldnames(secs{end}.alignments);
    alignment = alignments{end};
end
if nargin < 3
    outline_only = true;
end

FaceColor = 'r';
FaceAlpha = 0.1;
EdgeColor = FaceColor;

figure, hold on
for s = 1:length(secs)
    tile_bbs = sec_bb(secs{s}, alignment);
    if outline_only
        % Merge tile bbs and get convex hull
        outline_pts = vertcat(tile_bbs{:});
        k = convhull(double(outline_pts(:,1)), double(outline_pts(:,2)), 'simplify', true);
        outline_bb = outline_pts(k, :);
        
        % Draw
        fill3(outline_bb(:,1), outline_bb(:,2), repmat(secs{s}.num, length(outline_bb), 1), FaceColor, 'FaceAlpha', FaceAlpha, 'EdgeColor', EdgeColor)
    else
        for t = 1:length(tile_bbs)
            % Draw
            bb = tile_bbs{t};
            fill3(bb(:,1), bb(:,2), repmat(secs{s}.num, length(bb), 1), FaceColor, 'FaceAlpha', FaceAlpha, 'EdgeColor', EdgeColor)
        end
    end
end


end

