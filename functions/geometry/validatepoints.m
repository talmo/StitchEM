function varargout = validatepoints(points, out_format)
%VALIDATEPOINTS Validates a list of points specified in different formats.
% Args:
%   points are the list of points to validate
%   out_format is a string containing the flags that specify the output
%       format (see below). Default is 'cm' => column matrix format
%
% Returns:
%   The points in the format specified by out_format (see below).
%       Throws error if cannot be converted.
%
% Format flags:
%   - out_format must be a combination of a Class, Shape and Other flags.
%   - These may be specified in any order.
%
%   Class (max 1):
%       'm' = matrix; returns a double array
%       'v' = vector; returns a 1-D double array for each dimension
%       'a' = cell array; returns a cell array
%   Shape (max 1):
%       'c' = column; column (block) vector => each row is a point
%       'r' = row; row (block) vector => each column is a point
%   Other:
%       'p' = polygon; ensures this is a closed polygonal chain (first point = last point)
%       'x' = convex; convex hull of the points (implies 'p')
%       's' = simple; no unnecessary collinear points (implies 'x')
%       '1' = points are padded with 1

if nargin < 2
    out_format = 'cm';
end

% Process flags
classes = 'mva';
shapes = 'cr';
polys = 'pxs';
out.class = classes(ismember(classes, lower(out_format)));
out.shape = shapes(ismember(shapes, lower(out_format)));
out.poly = polys(find(ismember(polys, lower(out_format)), 1));
out.pad1 = any(strfind(out_format, '1'));

% Detect input format


end

