function current_path = renderpath(new_path)
%RENDERPATH Alias for renderspath.
% See also: renderspath

if nargin > 0
    current_path = renderspath(new_path);
else
    current_path = renderspath();
end

end

