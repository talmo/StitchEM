%% Sample
sample.xy = vertcat(data.xy);
sample.z = vertcat(data.z);

%% Descriptive
figure
boxplot(sample.xy.post), hold on
boxplot(sample.z.post)