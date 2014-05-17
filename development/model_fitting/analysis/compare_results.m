%% Load data sets
experimental = 'sp_lsq_z';
control = 'lsq';
%control = 'control-(0.125x,gmm,geomedian-inliers,cpd)';

A = readtable(['W003-sec1-100-(no_rough_z)/' experimental '.csv']);
B = readtable(['W003-sec1-100-(no_rough_z)/' control '.csv']);

%% Exclude outliers
outliersA = A.sec == 72 | A.sec == 73;
inliersA = ~outliersA;
A = A(inliersA, :);

outliersB = B.sec == 72 | B.sec == 73;
inliersB = ~outliersB;
B = B(inliersB, :);
%inliers = data([2:70 73:99], :);

%% Descriptive
% table of A vs B (cols)
disp('<strong>Experimental</strong>')
summary(A(:, 'post_errors'))
disp('<strong>Control</strong>')
summary(B(:, 'post_errors'))

%% Visualize
% Boxplots side by side
figure
boxplot([A.post_errors, B.post_errors], 'labels', {'Experimental', 'Control'})
title('Average error after alignment')

%% Hypothesis testing
% Two-sample t-test (assuming equal variance)
%   Null: samples come from normal distributions with equal mean
%   Alt: samples come from distributions with unequal means
[~, ttest2_equalvar_p] = ttest2(A.post_errors, B.post_errors, 'Vartype', 'equal');
fprintf('Two-sample t-test (equal variance): p = %g\n', ttest2_equalvar_p)

% Two-sample t-test (without assuming equal variance)
%   Null: samples come from normal distributions with equal mean
%   Alt: samples come from distributions with unequal means
[~, ttest2_unequalvar_p] = ttest2(A.post_errors, B.post_errors, 'Vartype', 'unequal');
fprintf('Two-sample t-test (unequal variance): p = %g\n', ttest2_unequalvar_p)

% Wilcoxon rank sum test
%   Null: samples come from continuous distributions with equal medians
%   Alt: samples come from continuous distributions with unequal medians
ranksum_p = ranksum(A.post_errors, B.post_errors);
fprintf('Wilcoxon rank sum test: p = %g\n', ranksum_p)

% Ansari-Bradley test
%   Null: samples come from distribution with same variance
%   Alt: sample come from distributions with same median and shape but
%        different variance
[~, ansaribradley_p] = ansaribradley(A.post_errors, B.post_errors);
fprintf('Ansari-Bradley test: p = %g\n', ansaribradley_p)

%% Visualize
% Bar charts of mean/median + error bars
figure
means = [mean(A.post_errors), mean(B.post_errors)];
bar(means, 'w'), hold on
errorbar(means, [std(A.post_errors), std(B.post_errors)], 'k+')
set(gca, 'XTickLabel', {'Experimental', 'Control'})
title('Mean average error after alignment')

% todo: add significance test line with asterisk(s) between bars