function cropped_R = crop_imref2d(R, region)
%CROP_IMREF2D Returns a cropped region of the spatial referencing object.
% Region must specify a box relative to the world coordinate system of R.
% Region types:
%   Bounding box: 5x2 matrix, see minabb or refmbb
%   Limits: 2x2 matrix, first row is XLimits, second row is YLimits
%   Position + size: 1x4 matrix, [x, y, width, height]

if all(size(region) == [5, 2])
    xlims = [min(region(:,1)), max(region(:,1))];
    ylims = [min(region(:,2)), max(region(:,2))];
elseif all(size(region) == [2, 2])
    xlims = region(1,:);
    ylims = region(2,:);
elseif all(size(region) == [1, 4])
    xlims = [region(1), region(1) + region(3)];
    ylims = [region(2), region(2) + region(4)];
end

[I, J] = R.worldToSubscript(xlims, ylims);
sz = [diff(I), diff(J)];

cropped_R = imref2d(sz, R.PixelExtentInWorldX, R.PixelExtentInWorldY);
cropped_R.XWorldLimits = xlims;
cropped_R.YWorldLimits = ylims;
end

