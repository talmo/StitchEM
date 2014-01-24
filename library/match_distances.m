function distances = match_distances(pointsA, pointsB)
%MATCH_DISTANCES Calculates the Euclidean distance between each pair of
% matching points.

distances = sqrt(sum((pointsA - pointsB) .^2, 2));

end

