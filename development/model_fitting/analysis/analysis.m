%% Save alignment data to table
alignment = 'z';
data = table();

data.sec = (secs{2}.num:secs{end}.num)';
data.prior_errors = cellfun(@(sec) sec.alignments.(alignment).meta.avg_prior_error, secs(2:end));
data.post_errors = cellfun(@(sec) sec.alignments.(alignment).meta.avg_post_error, secs(2:end));
data.change = post_errors - prior_errors;
data.num_matches = cellfun(@(sec) sec.z_matches.num_matches, secs(2:end));

%% Plot errors
figure
bar(data.sec, data.post_errors)
title('Average error after Z alignment')
xlabel('Section'), ylabel('Average error (px / match)')
axis tight

figure
hist(data.post_errors)
title('Distribution of average error after Z alignment')
xlabel('Average error (px / match)'), ylabel('Frequency')
axis tight

%% Distribution
% Check if errors are normally distributed
figure
normplot(data.post_errors)

%% Hypothesis: Are the number of matches correlated with error?
% Ref: http://stats.stackexchange.com/questions/8071/how-to-choose-between-pearson-and-spearman-correlation
[spearman_rho, spearman_p] = corr(data.num_matches, data.post_errors, 'type', 'spearman');
[pearson_rho, pearson_p] = corr(data.num_matches, data.post_errors, 'type', 'pearson');
figure
plot(data.num_matches, data.post_errors, 'ko', 'MarkerFaceColor', 'k')
grid on
xlabel('Number of matches'), ylabel('Average error (px / match)')
title({'\bfCorrelation between number of matches and average error\rm',
    sprintf('Spearman''s rho = %.2f (p = %.3f) | Pearson''s rho = %.2f (p = %.3f) | n = %d sections', spearman_rho, spearman_p, pearson_rho, pearson_p, height(data))});

%% Hypothesis: Do errors propagate across sections?
[spearman_rho, spearman_p] = corr(data.sec, data.post_errors, 'type', 'spearman');
[pearson_rho, pearson_p] = corr(data.sec, data.post_errors, 'type', 'pearson');
figure
plot(data.sec, data.post_errors, 'ko', 'MarkerFaceColor', 'k')
grid on
xlabel('Section number'), ylabel('Average error (px / match)')
title({'\bfCorrelation between section number and average error\rm',
    sprintf('Spearman''s rho = %.2f (p = %.3f) | Pearson''s rho = %.2f (p = %.3f) | n = %d sections', spearman_rho, spearman_p, pearson_rho, pearson_p, height(data))});