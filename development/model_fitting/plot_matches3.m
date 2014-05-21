%% Plot secA
figure, hold on

alignment = 'z';
FaceColor = 'r';
FaceAlpha = 0.1;
EdgeColor = FaceColor;

tile_bbs = sec_bb(secA, alignment);
for t = 1:length(tile_bbs)
    % Draw
    bb = tile_bbs{t};
    fill3(bb(:,1), bb(:,2), repmat(secA.num, length(bb), 1), FaceColor, 'FaceAlpha', FaceAlpha, 'EdgeColor', EdgeColor)
end

%% Plot secB
alignment = 'xy';
FaceColor = 'g';
FaceAlpha = 0.1;
EdgeColor = FaceColor;

tile_bbs = sec_bb(secB, alignment);
for t = 1:length(tile_bbs)
    % Draw
    bb = tile_bbs{t};
    fill3(bb(:,1), bb(:,2), repmat(secB.num, length(bb), 1), FaceColor, 'FaceAlpha', FaceAlpha, 'EdgeColor', EdgeColor)
end

%% Plot matches
M = secB.z_matches;

% Points
plot3(M.A.global_points(:,1), M.A.global_points(:,2), repmat(secA.num, height(M.A), 1), 'ro')
plot3(M.B.global_points(:,1), M.B.global_points(:,2), repmat(secB.num, height(M.B), 1), 'g+')

% Lines
lineX = [M.A.global_points(:,1)'; M.B.global_points(:,1)'];
numPts = numel(lineX);
lineX = [lineX; NaN(1,numPts/2)];
lineY = [M.A.global_points(:,2)'; M.B.global_points(:,2)'];
lineY = [lineY; NaN(1,numPts/2)];
lineZ = [repmat(secA.num, 1, numPts/2); repmat(secB.num, 1, numPts/2)];
lineZ = [lineZ; NaN(1,numPts/2)];
plot3(lineX(:), lineY(:), lineZ(:), 'y-');
%plot3(M.A.global_points(:,1), M.A.global_points(:,2), repmat(secA.num, height(M.A), 1), 'ro')