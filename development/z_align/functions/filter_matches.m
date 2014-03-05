function [filteredA, filteredB, idx] = filter_matches(matchesA, matchesB, variable, criteria, which_set)
%FILTER_MATCHES Returns rows of the match set that meets the criteria.
% Usage:
%   [filteredA, filteredB, idx] = filter_matches(A, B, variable, criteria);
%   [filteredA, filteredB, idx] = filter_matches(A, B, variable, criteria, which_set);
%   which_set: which set to match,'A', 'B', or 'both'

if nargin < 5
    which_set = 'both';
end

idx = zeros(size(matchesA, 1), 1);

switch which_set
    case 'A'
        idx = matchesA.(variable) == criteria;
    case 'B'
        idx = matchesB.(variable) == criteria;
    case 'both'
        idx = matchesA.(variable) == criteria | matchesB.(variable) == criteria;
end

filteredA = matchesA(idx, :);
filteredB = matchesB(idx, :);

end

