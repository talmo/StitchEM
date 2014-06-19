%C:\Users\Talmo\Dropbox\MIT\data\analysis\W002-W005

%% Sample
sample.xy = vertcat(data.xy);
sample.z = vertcat(data.z);
sample.size = height(sample.xy);

%% Summary statistics
alignment_types = {'xy', 'z'};
data_fields = {'prior', 'post', 'num_matches', 'runtime'};
for alignment_type = alignment_types
    a = alignment_type{1};
    for data_field = data_fields
        f = data_field{1};
        
        % Get field values
        X = sample.(a).(f)(~isnan(sample.(a).(f)));
        
        % Summary stats
        stats.(a).(f).n = sum(~isnan(X));
        stats.(a).(f).median = nanmedian(X);
        stats.(a).(f).mean = nanmean(X);
        stats.(a).(f).std = nanstd(X);
        stats.(a).(f).min = nanmin(X);
        stats.(a).(f).max = nanmax(X);
        stats.(a).(f).sum = nansum(X);
    end
end

%% Boxplots (post error)
figure
subplot(2,1,1), boxplot(sample.xy.post, 'labels', 'XY', 'orientation', 'horizontal')
text(stats.xy.post.min, 0.75, ...
    sprintf('\\bfMean\\rm: %.3f \\pm %.3f px / match', stats.xy.post.mean, stats.xy.post.std))
title(sprintf('\\bfPost-alignment error\\rm (n = %d sections)', sample.size))
subplot(2,1,2), boxplot(sample.z.post, 'labels', 'Z', 'orientation', 'horizontal')
text(stats.z.post.min, 0.75, ...
    sprintf('\\bfMean\\rm: %.3f \\pm %.3f px / match', stats.z.post.mean, stats.z.post.std))
xlabel('\bfAverage error\rm (px / match)')

%% Runtimes
figure

% Pie chart
runtime_labels = {sprintf('XY (%.2f%%)', stats.xy.runtime.mean / (stats.xy.runtime.mean + stats.z.runtime.mean) * 100), ...
    sprintf('Z (%.2f%%)', stats.z.runtime.mean / (stats.xy.runtime.mean + stats.z.runtime.mean) * 100)};
pie([stats.xy.runtime.mean, stats.z.runtime.mean], runtime_labels);

% Data table
% runtime_cols = {'Median', 'Mean', 'SD', 'Total'};
% runtime_rows = {'XY', 'Z', 'Both'};
% runtime_stats = [struct2array(stats.xy.runtime); struct2array(stats.z.runtime)];
% runtime_stats = num2cell([runtime_stats(:,[2:4,end]); sum(runtime_stats(:,[2:4,end]))]);
% runtime_stats(:,end) = cellfun(@(s) secs2str(s), runtime_stats(:,end), 'UniformOutput', false);
% uitable('Data', runtime_stats, 'Units', 'pixels', 'Position', [30, 5, 482, 76], 'RowName', runtime_rows, 'ColumnName', runtime_cols, 'ColumnWidth', {'auto', 'auto', 'auto', 200});

title(sprintf('\\bfRuntimes\\rm (n = %d sections)', sample.size))

