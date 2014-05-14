function [Px, Py] = validatepoints(points, varargin)
%VALIDATEPOINTS Validates a list of 2-D points and returns them as column vectors.
% Usage:
%   [Px, Py] = validatepoints(points)
%   [Px, Py] = validatepoints(Px, Py)
%   P = validatepoints(...)

% Create inputParser instance
p = inputParser;

% Arguments
p.addRequired('Px', @(x) validateattributes(x, {'numeric'}, {'2d', 'nonempty'}));
p.addOptional('Py', [], @(x) validateattributes(x, {'numeric'}, {'vector'}));

% Parse
p.parse(points, varargin{:});

% Format
if isvector(p.Results.Px) && length(p.Results.Px) == length(p.Results.Py)
    % Ensure Px and Py are column vectors
    Px = p.Results.Px(:);
    Py = p.Results.Py(:);
    
elseif any(size(p.Results.Px) == 2)
    % Matrix of points specified
    P = p.Results.Px;
    
    % Ensure P is a vertical matrix
    if size(P, 2) ~= 2 % if size(P) = [1, 2] it's still vertical
        P = P';
    end
    
    % Split into vectors
    Px = P(:, 1);
    Py = P(:, 2);
else
    error('Points must be specified as a Mx2 or 2xM matrix, or by two Mx1 or 1xM vectors.')
end

% Output
if nargout < 2
    Px = [Px Py];
end
end

