function plot_matches(pointsA, pointsB)
%PLOT_MATCHES Plots point matches on top of each other and displays some
%basic statistics on the matches.

%% Parameters
tileRes = 8000;
overlap = 0.1;

%% Adjust figure
figure, hold on
xlim([0 4 * tileRes * (1 - overlap)])
ylim([0 4 * tileRes * (1 - overlap)])
set(gca, 'XTick', (1:4) * tileRes * (1 - overlap));
set(gca, 'YTick', (1:4) * tileRes * (1 - overlap));
set(gca,'YDir','reverse');
grid on

%% Plot points
plot(pointsA(:,1), pointsA(:,2), 'rx');
plot(pointsB(:,1), pointsB(:,2), 'bx');

%% Plot lines between point matches
numPts = size(pointsA, 1);

lineX = [pointsA(:, 1)'; pointsB(:, 1)'];
lineX = [lineX; NaN(1, numPts / 2)];

lineY = [pointsA(:, 2)'; pointsB(:, 2)'];
lineY = [lineY; NaN(1, numPts / 2)];

plot(lineX(:), lineY(:), 'g');

hold off

%% Display statistics on matches
distances = sqrt(sum((pointsA - pointsB) .^2, 2));

fprintf(['n = %d matches\n' ...
         'Mean = %f px\n' ...
         'Median = %f px\n' ...
         'Min = %f\n' ...
         'Max = %f\n' ...
         'STD = %f\n'], ...
         numel(distances), mean(distances), median(distances), min(distances), max(distances), std(distances))

end

