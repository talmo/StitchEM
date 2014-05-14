function composed = compose_tforms(tform1, tform2, varargin)
%COMPOSE_TFORMS Composes a number of linear transforms and returns the result as an affine2d() object.
% Usage:
%   tform = compose_tforms(tform1, ..., tformN)
%
% Notes:
%   - The input transforms can be any combination of affine2d or 3x3 double
%   matrices.
%   - These transforms are composed from left to right in the order of the
%   arguments.

if nargin < 2
    error('Must input at least two transforms.')
end

% Combine arguments
tforms = [{tform1}, {tform2}, varargin];

% Find the number of tforms per set
[max_size, idx] = max(cellfun(@numel, tforms));
output_size = size(tforms{idx});

% Validate inputs
for i = 1:numel(tforms)
    switch class(tforms{i})
        case 'affine2d'
            tforms{i} = tforms{i}.T;
        case 'cell'
            if numel(tforms{i}) ~= 1 && numel(tforms{i}) ~= max_size
                error('Every set of transforms must be of the same size.')
            end
            
            for j = 1:numel(tforms{i})
                if isa(tforms{i}{j}, 'affine2d')
                    tforms{i}{j} = tforms{i}{j}.T;
                else
                    validateattributes(tforms{i}{j}, {'numeric'}, {'size', [3, 3]})
                end
            end
        otherwise
            validateattributes(tforms{i}, {'numeric'}, {'size', [3, 3]})
    end
end

% Initialize to identity
composed = repmat({eye(3)}, output_size);

% Compose transforms
for i = 1:numel(tforms)
    for j = 1:numel(composed)
        if iscell(tforms{i})
            composed{j} = composed{j} * tforms{i}{j};
        else
            composed{j} = composed{j} * tforms{i};
        end
    end
end

% Convert to affine2d
composed = cellfun(@(T) affine2d(T), composed, 'UniformOutput', false);

if max_size == 1
    composed = composed{1};
end

end

