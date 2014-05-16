function out = out2(f, concatenate)
%OUT2 Returns the output of calling the function with two output arguments.
% Usage:
%   out = out2(f)
%   out = out2(f, false) % does not concatenate output
%
% Returns a cell array or a concatenation of the outputs if possible.

[out{1:2}] = f();

% Concatenate outputs
if (nargin == 1 || concatenate) && ... % user wants to concatenate
        strcmp(class(out{1}), class(out{2})) && ... % same class
        ndims(out{1}) == ndims(out{2}) && ... % same dimensions
        ~isobject(out{1}) && ~iscell(out{1}) && ... % not object or cell
        (~isstruct(out{1}) || isempty(setxor(fieldnames(out{1}), fieldnames(out{2})))) % same fieldnames if struct
    
    n = find(size(out{1}) ~= size(out{2}));
    switch numel(n)
        case 0
            out = horzcat(out{:});
        case 1
            out = cat(n, out{:});
    end
end
end

