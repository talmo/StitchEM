function bb_out = tform_bb2bb(bb, tform, pixel_res)
%TFORM_BB2BB Applies a geometric transformation to a bounding box and returns the bounding box of the result.
% Consistent with imwarp and imref2d behavior.
%
% See also: tform_spatial_ref

if nargin < 3
    pixel_res = [1.0, 1.0];
end
XRes = pixel_res(1);
YRes = pixel_res(2);

% Get limits of input bounding box
[XLims_in, YLims_in] = bb2lims(bb);

% Get limits of output bounding box
[XLims_out, YLims_out] = tform.outputLimits(XLims_in, YLims_in);

% Find the size of the grid with the specified resolution
num_cols = ceil(diff(XLims_out) / XRes);
num_rows = ceil(diff(YLims_out) / YRes);

% Adjust the limits such that the center of the bounding box remains fixed
x_nudge = (num_cols * XRes - diff(XLims_out)) / 2;
y_nudge = (num_rows * YRes - diff(YLims_out)) / 2;

% Apply adjustment to limits of output
XLims_out = XLims_out + [-x_nudge x_nudge];
YLims_out = YLims_out + [-y_nudge y_nudge];

% Return output bounding box
bb_out = lims2bb(XLims_out, YLims_out);


end

