function n = width(A)
%WIDTH Returns the number of columns of an array. Shortcut for size(A, 2).

validateattributes(A, {'numeric', 'cell'}, {'2d'})

n = size(A, 2);

end

