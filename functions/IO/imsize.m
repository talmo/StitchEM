function sz = imsize(path, num)
%IMSIZE Returns the size of an image.
%
% Usage:
%   sz = imsize(path)
%   sz = imsize(path, num)
%
% Args:
%   path is the full path to the image file
%   num is the number of the image in the file, in case the file contains
%       more than one image. Defaults to 1.
%
% Returns:
%   sz = [height width] of the image in the file.
%
% See also: imfinfo, get_tile_size

if nargin < 2
    num = 1;
end

info = imfinfo(path);
sz = [info(num).Height, info(num).Width];

end

