%% Save alignment data to table
alignment = 'xy';
data = table();

data.sec = (secs{2}.num:secs{end}.num)';
data.prior_errors = cellfun(@(sec) sec.alignments.(alignment).meta.avg_prior_error, data.sec);
data.post_errors = cellfun(@(sec) sec.alignments.(alignment).meta.avg_post_error, data.sec);
data.change = data.post_errors - data.prior_errors;
data.num_matches = cellfun(@(sec) sec.z_matches.num_matches, data.sec);

%% Exclude outliers
outliers = data.sec == 72 | data.sec == 73;
inliers = ~outliers;
data = data(inliers, :);
%inliers = data([2:70 73:99], :);

summary(data)

%% Plot errors
figure
bar(data.sec, data.post_errors)
title('Average error after Z alignment')
xlabel('Section'), ylabel('Average error (px / match)')
axis tight

figure
hist(data.post_errors, 30)
title('Distribution of average error after Z alignment')
xlabel('Average error (px / match)'), ylabel('Frequency')
axis tight

figure
boxplot(data.post_errors)
title('Average error after Z alignment')

tilefigs

%% Distribution
% Check if errors are normally distributed
figure
normplot(data.post_errors)

%% Hypothesis: Are the number of matches correlated with error?
% Spearman: correlation between samples is monotonic
% Pearson: correlation between samples is linear
% Null: Correlation is zero
% Alt: There is a non-zero correlation
% Ref: http://stats.stackexchange.com/questions/8071/how-to-choose-between-pearson-and-spearman-correlation
[spearman_rho, spearman_p] = corr(data.num_matches, data.post_errors, 'type', 'spearman');
[pearson_rho, pearson_p] = corr(data.num_matches, data.post_errors, 'type', 'pearson');
figure
plot(data.num_matches, data.post_errors, 'ko', 'MarkerFaceColor', 'k')
grid on
xlabel('Number of matches'), ylabel('Average error (px / match)')
title('\bfCorrelation between number of matches and average error\rm')
append_title(sprintf('n = %d sections', height(data)))
append_title(sprintf('Spearman''s rho = %.2f (p = %g)', spearman_rho, spearman_p))
append_title(sprintf('Pearson''s rho = %.2f (p = %g)', pearson_rho, pearson_p))

%% Hypothesis: Do errors propagate across sections?
[spearman_rho, spearman_p] = corr(data.sec, data.post_errors, 'type', 'spearman');
[pearson_rho, pearson_p] = corr(data.sec, data.post_errors, 'type', 'pearson');
figure
plot(data.sec, data.post_errors, 'ko', 'MarkerFaceColor', 'k')
grid on
xlabel('Section number'), ylabel('Average error (px / match)')
title('\bfCorrelation between section number and average error\rm')
append_title(sprintf('n = %d sections', height(data)))
append_title(sprintf('Spearman''s rho = %.2f (p = %g)', spearman_rho, spearman_p))
append_title(sprintf('Pearson''s rho = %.2f (p = %g)', pearson_rho, pearson_p))

%% Hypothesis: Is the prior error correlated with post error?
[spearman_rho, spearman_p] = corr(data.prior_errors, data.post_errors, 'type', 'spearman');
[pearson_rho, pearson_p] = corr(data.prior_errors, data.post_errors, 'type', 'pearson');
figure
plot(data.prior_errors, data.post_errors, 'ko', 'MarkerFaceColor', 'k')
grid on
xlabel('Average pre-alignment error (px / match)'), ylabel('Average post-alignment error (px / match)')
title('\bfCorrelation between error before and after alignment\rm')
append_title(sprintf('n = %d sections', height(data)))
append_title(sprintf('Spearman''s rho = %.2f (p = %g)', spearman_rho, spearman_p))
append_title(sprintf('Pearson''s rho = %.2f (p = %g)', pearson_rho, pearson_p))

%% Linear regression


% Fit model
lm = fitlm([data.sec, data.num_matches, data.prior_errors], data.post_errors, 'VarNames', {'sec', 'num_matches', 'prior_error', 'post_error'})