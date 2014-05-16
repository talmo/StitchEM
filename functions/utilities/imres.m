function res = imres(im)
%IMRES Returns the [x, y] resolution of the image.
% Usage:
%   res = imres(im);
%
% Note: This is just a shortcut for fliplr(size(im)).
%
% See also: imsize

res = fliplr(size(im));

end

