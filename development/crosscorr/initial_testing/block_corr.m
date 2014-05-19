function result = block_corr(blockstruct, A)
%BLOCK_CORR Helper function

x = blockstruct.data;

% check if flat
if std(double(x(:))) == 0
    offset = [NaN, NaN];
    return
end

C = normxcorr2(x, A);

% index
[~, peak] = max(C(:));

% row, col
[peak(1), peak(2)] = ind2sub(size(C), peak);

% offset
offset = peak - size(x) - blockstruct.location + [1, 1];
%offset = blockstruct.location;

result = offset;
%result = [blockstruct.location, offset];

end

