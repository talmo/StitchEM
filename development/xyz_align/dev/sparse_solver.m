% Loads matches for a stack of sections and calculates their alignment transforms.
%
% Don't use this script, this was mostly used for developing the sparse
% version of the Tikhonov solver.

%% Load matches
clear, clc
%load('sec31-86_matches.mat')
%load('sec100-103_matches.mat')
%load('sec100-114_matches.mat')
load('sec100-149_matches.mat')

%% Try to solve for one lambda

%[tforms, mean_error] = align_section_stack(secs, matchesA, matchesB, 'lambda', 0.05, 'sparse_solver', false);
profile on
[tforms_sp, mean_error_sp] = align_section_stack(secs, matchesA, matchesB, 'lambda', 0.05, 'sparse_solver', true);
profile viewer


%% Sparse
sec_nums = unique([matchesA.section(:); matchesB.section(:)]);
num_secs = length(sec_nums);
tile_nums = arrayfun(@(s) unique([matchesA.tile(matchesA.section == s); matchesB.tile(matchesB.section == s)]), sec_nums, 'UniformOutput', false);
num_tiles = cellfun(@(t) length(t), tile_nums);
cum_num_tiles = cumsum(num_tiles) - num_tiles(1);

total_tiles = cum_num_tiles(end) + num_tiles(1);
num_matches = height(matchesA);

tic;
Ja = zeros(height(matchesA), 1);
Jb = zeros(height(matchesB), 1);
for s = 1:num_secs
    tile_idx = zeros(1, length(tile_nums{s}));
    for t = min(tile_nums{s}):max(tile_nums{s})
        idx = find(tile_nums{s} == t, 1);
        if ~isempty(idx)
            tile_idx(t) = idx;
        end
    end
    
    Ia = matchesA.section == sec_nums(s);
    Ja(Ia) = cum_num_tiles(s) * 3 + (tile_idx(matchesA.tile(Ia)) - 1) * 3 + 1;
    
    Ib = matchesB.section == sec_nums(s);
    Jb(Ib) = cum_num_tiles(s) * 3 + (tile_idx(matchesB.tile(Ib)) - 1) * 3 + 1;
end

Ia = repmat((1:num_matches)', 3, 1);
Ib = repmat((1:num_matches)', 3, 1);

Ja = [Ja; Ja + 1; Ja + 2];
Jb = [Jb; Jb + 1; Jb + 2];

Sa = -[double(matchesA.global_points(:)); ones(num_matches, 1)];
Sb = [double(matchesB.global_points(:)); ones(num_matches, 1)];

m = num_matches;
n = total_tiles * 3;
nnzA = num_matches * 3;
nnzGamma = nnzA * 2;

A = sparse(Ib, Jb, Sb, m, n, nnzA);
gamma = sparse([Ib; Ia], [Jb; Ja], [Sb; Sa], m, n, nnzGamma);
b = reshape(Sb, num_matches, 3);
toc
tic;
params.lambda = 0.05;
x_hat = full((params.lambda .^ 2 * (A' * A) + gamma' * gamma) \ (params.lambda .^ 2 * A' * b));
toc

A_sp = A;
gamma_sp = gamma;
b_sp = b;
x_hat_sp = x_hat;

%% Old
tic;
sec_nums = unique([unique(matchesA.section); unique(matchesB.section)]);
num_secs = length(sec_nums);
num_matches = size(matchesA, 1);
tile_nums = arrayfun(@(sec) unique([matchesA.tile(matchesA.section == sec); matchesB.tile(matchesB.section == sec)]), sec_nums, 'UniformOutput', false);
num_sec_tiles = cellfun(@(x) length(x), tile_nums);
num_tiles = sum(num_sec_tiles);

% Use indices instead of the actual tile/section number
secIdxA = arrayfun(@(s) find(sec_nums == s), matchesA.section);
secIdxB = arrayfun(@(s) find(sec_nums == s), matchesB.section);
tileIdxA = cellfun(@(sec_tile) find(tile_nums{sec_tile(1)} == sec_tile(2)), num2cell([secIdxA matchesA.tile], 2));
tileIdxB = cellfun(@(sec_tile) find(tile_nums{sec_tile(1)} == sec_tile(2)), num2cell([secIdxB matchesB.tile], 2));

% Pre-allocate matrices
A = zeros(num_matches, num_tiles * 3);
gamma = zeros(num_matches, num_tiles * 3);

% Calculate the column indices for each point
colA = arrayfun(@(s) sum(num_sec_tiles(1:s-1)), secIdxA) * 3 + (tileIdxA - 1) * 3 + 1;
colB = arrayfun(@(s) sum(num_sec_tiles(1:s-1)), secIdxB) * 3 + (tileIdxB - 1) * 3 + 1;

% Pad the points
ptsA_padded = [matchesA.global_points ones(num_matches, 1)];
ptsB_padded = [matchesB.global_points ones(num_matches, 1)];

% The b vector is pretty trivial, just the moving points padded with ones
b = double(ptsB_padded);

% Fill out matrices with matched points
for i = 1:num_matches
    % Fill in row for rigidity matrix (A)
    A(i, colB(i):colB(i) + 2) = ptsB_padded(i, :);
    
    % Fill in row for alignment matrix (gamma)
    gamma(i, colB(i):colB(i) + 2) = ptsB_padded(i, :);
    gamma(i, colA(i):colA(i) + 2) = -ptsA_padded(i, :);
end

% Solve
x_hat = (params.lambda .^ 2 * (A' * A) + gamma' * gamma) \ (params.lambda .^ 2 * A' * b);
toc
%% Compare
A = sparse(A);
gamma = sparse(gamma);

%find(any(A_sp ~= A, 2), 1)
all(all(A_sp == A))
all(all(gamma_sp == gamma))
all(all(b_sp == b))
all(all(x_hat_sp == x_hat))