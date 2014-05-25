secA = secs{1};
secB = secs{2};

%% Visualize sections
figure
plot_section(secA);
plot_section(secB);

%% Calculate intersections
bbA = sec_bb(secA, 'z');
bbB = sec_bb(secB, 'z');
[I, idx] = intersect_poly_sets(bbA, bbB);

%% Filter to just full tile overlaps
diag_idx = [idx{sub2ind(size(idx), 1:size(idx, 1), 1:size(idx, 2))}];
tileI = I(diag_idx);

%% Visualize
figure
draw_polys(tileI)
axis ij equal

%% Figure out world extents
bbWorld = minaabb(vertcat(tileI{:}));
[XLims, YLims] = bb2lims(bbWorld);

%% Make a grid
grid_sz = 2000;
block_sz = 200;
search_sz = 200;

[gridX, gridY] = meshgrid(XLims(1):grid_sz:XLims(2), YLims(1):grid_sz:YLims(2));
%locations = [gridX(:), gridY(:)];

blocks = arrayfun(@(x, y) rect2bb([x, y, block_sz, block_sz]), gridX, gridY, 'UniformOutput', false);
search = arrayfun(@(x, y) rect2bb([x - search_sz, y - search_sz, 2 * search_sz + block_sz, 2 * search_sz + block_sz]), gridX, gridY, 'UniformOutput', false);

% Eliminate any that intersect with tile bounds
valid = cellfun(@(rI) any(cellfun(@(tI) all(inpolygon(rI(:,1), rI(:,2), tI(:,1), tI(:,2))), tileI)), search);
valid_blocks = blocks(valid);
valid_search = search(valid);

%% Visualize
figure
draw_poly(bbWorld, 'g0.1'), hold on
draw_polys(tileI, 'y0.3')
draw_polys(valid_search, 'b0.4')
draw_polys(valid_blocks, 'r0.5')
plot(gridX, gridY, 'k+')
axis ij equal

%% Calculate Rs
[stack_R, sec_Rs] = stack_ref(secs, 'z');

%% Get image data
t = 1;

% Load tile images
tileA = imload_tile(secA.num, t);
tileB = imload_tile(secB.num, t);

% Spatial refs
RA = sec_Rs{1}{t};
RB = sec_Rs{2}{t};

% Transform
tileA = imwarp(tileA, secA.alignments.z.tforms{t}, 'OutputView', RA);
tileB = imwarp(tileB, secB.alignments.z.tforms{t}, 'OutputView', RB);

% Block and search area limits
i = 1;
[XLimsA, YLimsA] = bb2lims(valid_search{i});
[XLimsB, YLimsB] = bb2lims(valid_blocks{i});

% Convert to coordinates
[srchI, srchJ] = RA.worldToSubscript(XLimsA, YLimsA);
[blokI, blokJ] = RB.worldToSubscript(XLimsB, YLimsB);

% Get image data
srch = tileA(srchI(1):srchI(2)-1, srchJ(1):srchJ(2)-1);
blok = tileB(blokI(1):blokI(2)-1, blokJ(1):blokJ(2)-1);

% Spatial ref
R_srch = imref2d(size(srch), XLimsA, YLimsA);
R_blok = imref2d(size(blok), XLimsB, YLimsB);

%% Visualize
%scale = 0.1;
%tileA_small = imresize(tileA, scale);
%RA_small = imref2d(size(tileA_small), RA.XWorldLimits, RA.YWorldLimits);

%% Visualize
figure
draw_poly(bbA{t}, 'c0.1')
draw_poly(bbB{t}, 'g0.1')
draw_poly(valid_search{i}, 'b0.4'), hold on
imshow(srch, R_srch)
draw_poly(valid_blocks{i}, 'r0.5'), hold on
imshow(blok, R_blok)

%% Cross correlation
[ptA, ptB] = find_xcorr(srch, R_srch, blok, R_blok);

%% Visualize
figure
draw_poly(bbA{t}, 'c0.1')
draw_poly(bbB{t}, 'g0.1')
draw_poly(valid_search{i}, 'b0.4')
draw_poly(valid_blocks{i}, 'r0.5')
plot_matches(ptA, ptB)