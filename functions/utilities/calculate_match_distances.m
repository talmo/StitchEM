function distances = calculate_match_distances(pointsA, pointsB, benchmark)
%MATCH_DISTANCES Calculates the Euclidean distance between each pair of matching points.

if nargin < 3
    benchmark = false;
end

if benchmark
    % Most straightforward way:
    tic
    distances = sqrt(sum((pointsA - pointsB) .^2, 2));
    toc

    % Calculate the norm of each point pair by breaking it into a cell array of rows:
    tic
    distances = cellfun(@norm, num2cell(pointsA - pointsB, 2));
    toc

    % Do the arithmetic per point dimension (column) in a loop:
    tic
    distances = zeros(size(pointsA, 1), 1);
    for i = 1:size(pointsA, 2)
        distances = distances + sum((pointsA(:, i) - pointsB(:, i)) .^2, 2);
    end
    distances = sqrt(distances);
    toc
else
    distances = sqrt(sum((pointsA - pointsB) .^2, 2));
end

end

