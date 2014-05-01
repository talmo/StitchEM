function [A_padded,B_padded,A_mask,B_mask,R_output] = calculateOverlayImages(A,RA,B,RB)

% First calculate output referencing object. World limits are minimum
% bounding box that contains world limits of both images. Resolution is the
% minimum resolution in each dimension. We don't want to down sample either
% image.

% From imfuse.m.

outputWorldLimitsX = [min(RA.XWorldLimits(1),RB.XWorldLimits(1)),...
                      max(RA.XWorldLimits(2),RB.XWorldLimits(2))];
                  
outputWorldLimitsY = [min(RA.YWorldLimits(1),RB.YWorldLimits(1)),...
                      max(RA.YWorldLimits(2),RB.YWorldLimits(2))];                 
                  
goalResolutionX = min(RA.PixelExtentInWorldX,RB.PixelExtentInWorldX);
goalResolutionY = min(RA.PixelExtentInWorldY,RB.PixelExtentInWorldY);

widthOutputRaster  = ceil(diff(outputWorldLimitsX) / goalResolutionX);
heightOutputRaster = ceil(diff(outputWorldLimitsY) / goalResolutionY);

R_output = imref2d([heightOutputRaster, widthOutputRaster]);
R_output.XWorldLimits = outputWorldLimitsX;
R_output.YWorldLimits = outputWorldLimitsY;

fillVal = 0;
A_padded = images.spatialref.internal.resampleImageToNewSpatialRef(A,RA,R_output,'bilinear',fillVal);
B_padded = images.spatialref.internal.resampleImageToNewSpatialRef(B,RB,R_output,'bilinear',fillVal);

[outputIntrinsicX,outputIntrinsicY] = meshgrid(1:R_output.ImageSize(2),1:R_output.ImageSize(1));
[xWorldOverlayLoc,yWorldOverlayLoc] = intrinsicToWorld(R_output,outputIntrinsicX,outputIntrinsicY);
A_mask = contains(RA,xWorldOverlayLoc,yWorldOverlayLoc);
B_mask = contains(RB,xWorldOverlayLoc,yWorldOverlayLoc);

end