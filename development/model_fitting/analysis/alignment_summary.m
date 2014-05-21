xy = readtable('xy.csv');
z = readtable('z.csv');
zcorr = readtable('zcorr.csv');

%% XY vs Zcorr
figure
boxplot([xy.post_errors, zcorr.post_errors], 'labels', {'XY', 'Z (block-corr)'})
append_title('\bfAverage error after alignment\rm')
append_title('n = 169 sections')
ylabel('avg pixels / match')

%% Z vs Zcorr
figure
boxplot([z.post_errors, zcorr.post_errors], 'labels', {'Z (features)', 'Z (block-corr)'})
append_title('\bfAverage error after alignment\rm')
append_title('n = 169 sections')
ylabel('avg pixels / match')