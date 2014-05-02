function sz = imsize(path)
%IMSIZE Returns the size of an image.
%
% Usage:
%   sz = imsize(path)
%
% Returns:
%   sz = [height width] of the first image in the file.
%
% See also: imfinfo, get_tile_size

info = imfinfo(path);
sz = [info(1).Height, info(1).Width];

end

