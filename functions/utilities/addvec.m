function B = addvec(A, V, dim)
%ADDVEC Adds a vector V from A at the specified dim.
% Usage:
%   B = addvec(A, -[1 1]); % subtracts [1 1] from every row in A
%   B = addvec(A, [5; 2], 2); % adds [5; 2] to each column in A

if nargin < 3
    dim = find(size(A) == size(V), 1);
elseif size(A, dim) ~= size(V, dim)
    error('A and V must have the same size in the specified dimension.')
end

B = A;
switch dim
    case 1
        for i = 1:size(A, 1)
            B(i, :) = A(i, :) + V(i);
        end
    case 2
        for i = 1:size(A, 2)
            B(:, i) = A(:, i) + V(i);
        end
end
    
end

