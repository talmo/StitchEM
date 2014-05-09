function R_output = merge_spatial_refs(Rs)
%MERGE_SPATIAL_REFS Combine several spatial referencing objects into one.
% Usage:
%   R_output = merge_spatial_refs(Rs)

outputWorldLimitsX = [min(cellfun(@(R) R.XWorldLimits(1), Rs)),...
                      max(cellfun(@(R) R.XWorldLimits(2), Rs))];

outputWorldLimitsY = [min(cellfun(@(R) R.YWorldLimits(1), Rs)),...
                      max(cellfun(@(R) R.YWorldLimits(2), Rs))];
                  
goalResolutionX = min(cellfun(@(R) R.PixelExtentInWorldX, Rs));
goalResolutionY = min(cellfun(@(R) R.PixelExtentInWorldY, Rs));

widthOutputRaster  = ceil(diff(outputWorldLimitsX) / goalResolutionX);
heightOutputRaster = ceil(diff(outputWorldLimitsY) / goalResolutionY);

% Adjust world limits to get precise target resolution
xNudge = (widthOutputRaster*goalResolutionX-diff(outputWorldLimitsX))/2;
yNudge = (heightOutputRaster*goalResolutionY-diff(outputWorldLimitsY))/2;
outputWorldLimitsX = outputWorldLimitsX + [-xNudge xNudge];
outputWorldLimitsY = outputWorldLimitsY + [-yNudge yNudge];

R_output = imref2d([heightOutputRaster, widthOutputRaster]);
R_output.XWorldLimits = outputWorldLimitsX;
R_output.YWorldLimits = outputWorldLimitsY;

end

