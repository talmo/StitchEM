%% Load data sets
A = readtable('W003_sec1-35_no-z-prev-composition_(gmm,cpd,no_rough_z).csv');
B = readtable('W003_sec1-71_smallest-error-inliers_(gmm,cpd,no_rough_z).csv');

%% Hypothesis testing
% Two-sample t-test (assuming equal variance)
%   Null: samples come from normal distributions with equal mean
%   Alt: samples come from distributions with unequal means
[~, ttest2_equalvar_p] = ttest2(A.post_errors, B.post_errors, 'Vartype', 'equal');
fprintf('Two-sample t-test (equal variance): p = %f\n', ttest2_equalvar_p)

% Two-sample t-test (without assuming equal variance)
%   Null: samples come from normal distributions with equal mean
%   Alt: samples come from distributions with unequal means
[~, ttest2_unequalvar_p] = ttest2(A.post_errors, B.post_errors, 'Vartype', 'unequal');
fprintf('Two-sample t-test (unequal variance): p = %f\n', ttest2_unequalvar_p)

% Wilcoxon rank sum test
%   Null: samples come from continuous distributions with equal medians
%   Alt: samples come from continuous distributions with unequal medians
ranksum_p = ranksum(A.post_errors, B.post_errors);
fprintf('Wilcoxon rank sum test: p = %f\n', ranksum_p)

% Ansari-Bradley test
%   Null: samples come from same distribution
%   Alt: sample come from distributions with same median and shape but
%        different variance
[~, ansaribradley_p] = ansaribradley(A.post_errors, B.post_errors);
fprintf('Ansari-Bradley test: p = %f\n', ansaribradley_p)

