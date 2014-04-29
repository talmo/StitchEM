%% Process data file
% Read in data
data = readtable('memorytrace_secs100-114.csv');
% data.Properties.VariableNames
% ans =
%   'sec'    'tile'    'time', 'freemem'

% Fill in missing section and tile values
for s = 1:max(data.sec)
    s_idx = find(data.sec == s);
    data.sec(s_idx(1):s_idx(2)) = s;
    
    data.tile(s_idx(1)) = 0; % about to start rendering section s
    data.tile(s_idx(2)) = -1; % just done rendering section s
end

% Accumulate time elapsed and interpolate missing values
data.time(1) = 0;
x = find(~isnan(data.time));
v = cumsum(data.time(x));
xq = (1:height(data))';
vq = interp1(x, v, xq, 'linear', 'extrap');
data.time = vq;

% Calculate relative memory usage
data.memused = max(data.freemem) - data.freemem;

%% Time vs memory
% Plot memory usage versus time
figure
stairs(data.time, data.memused, 'LineWidth', 2.0)
xlim([min(data.time) max(data.time)])
xlabel('Time elapsed (sec)'), ylabel('Memory used (MB)')
title(sprintf('Max memory usage = %f MB', max(data.memused)))

% Indicate start of each section
hold on
for s = 1:max(data.sec)
    t = data.time(find(data.sec == s, 1));
    plot([t t], ylim, 'r--', 'LineWidth', 0.5)
    text([t NaN], ylim, sprintf('Section %d', s), ...
        'Rotation', 90, 'VerticalAlignment', 'top', ...
        'HorizontalAlignment', 'left', 'FontWeight', 'bold')
end
hold off