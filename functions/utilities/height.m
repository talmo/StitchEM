function n = height(A)
%HEIGHT Returns the number of rows of an array. Shortcut for size(A, 1).

validateattributes(A, {'numeric', 'cell'}, {'2d'})

n = size(A, 1);

end

