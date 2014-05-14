function R = bb2ref(bb, pixel_res)
%BB2REF Returns the spatial referencing object of a region bounded by the bounding box.
% Usage:
%   R = bb2ref(bb)
%   R = bb2ref(bb, pixel_res) % pixel_res = [XRes, YRes]
%
% Note: This is consistent with imwarp and imref2d behavior. It adjusts the
% global X and Y coordinates to get the desired output resolution.
%
% See also: tform_spatial_ref, tform_bb2bb

if nargin < 2
    pixel_res = [1.0, 1.0];
end
XRes = pixel_res(1);
YRes = pixel_res(2);

% Get the world limits of the bounding box
[XLims, YLims] = bb2lims(bb);

% Find the size of the grid with the specified resolution
num_cols = ceil(diff(XLims) / XRes);
num_rows = ceil(diff(YLims) / YRes);
image_size = [num_rows num_cols];

% Adjust the limits such that the center of the bounding box remains fixed
x_nudge = (num_cols * XRes - diff(XLims)) / 2;
y_nudge = (num_rows * YRes - diff(YLims)) / 2;

% Apply adjustment to limits of output
XLims = XLims + [-x_nudge x_nudge];
YLims = YLims + [-y_nudge y_nudge];

% Creat the spatial referencing object
R = imref2d(image_size, XLims, YLims);

end

