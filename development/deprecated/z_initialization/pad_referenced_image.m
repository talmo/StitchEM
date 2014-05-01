function A_padded = pad_referenced_image(A, RA, RB)
%PAD_REFERENCED_IMAGE Pads a spatially referenced image.
% Same as calculateOverlayImages but with just one image.
outputWorldLimitsX = [min(RA.XWorldLimits(1),RB.XWorldLimits(1)),...
                      max(RA.XWorldLimits(2),RB.XWorldLimits(2))];
                  
outputWorldLimitsY = [min(RA.YWorldLimits(1),RB.YWorldLimits(1)),...
                      max(RA.YWorldLimits(2),RB.YWorldLimits(2))];                 
                  
goalResolutionX = min(RA.PixelExtentInWorldX,RB.PixelExtentInWorldX);
goalResolutionY = min(RA.PixelExtentInWorldY,RB.PixelExtentInWorldY);

widthOutputRaster  = ceil(diff(outputWorldLimitsX) / goalResolutionX);
heightOutputRaster = ceil(diff(outputWorldLimitsY) / goalResolutionY);

R_final = imref2d([heightOutputRaster, widthOutputRaster]);
R_final.XWorldLimits = outputWorldLimitsX;
R_final.YWorldLimits = outputWorldLimitsY;

fillVal = 0;
A_padded = images.spatialref.internal.resampleImageToNewSpatialRef(A,RA,R_final,'bilinear',fillVal);
end

