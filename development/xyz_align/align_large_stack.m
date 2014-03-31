%% Load matches
clear, clc
%load('sec31-86_matches.mat')
%load('sec100-103_matches.mat')
load('sec100-114_matches.mat')
%load('sec100-149_matches.mat')

%% Try to solve for one lambda
tic
[~, mean_error] = align_section_stack(secs, matchesA, matchesB, 'lambda', 0.05, 'sparse_solver', false)
toc

tic
[~, mean_error] = align_section_stack(secs, matchesA, matchesB, 'lambda', 0.05, 'sparse_solver', true)
toc

% - Setting up the matrices then making them sparse before solving saves
% ~2sec of runtime
% - Seting up the matrices as sparse and pre-allocating exact nnz elements
% still takes ~32 sec with loop


%% Scratch
sec_nums = unique([matchesA.section(:); matchesB.section(:)]);
num_secs = length(sec_nums);
tile_nums = arrayfun(@(s) unique([matchesA.tile(matchesA.section == s); matchesB.tile(matchesB.section == s)]), sec_nums, 'UniformOutput', false);
num_tiles = cellfun(@(t) length(t), tile_nums);
cum_num_tiles = cumsum(num_tiles) - num_tiles(1);

total_tiles = cum_num_tiles(end);
num_matches = height(matchesA);

tic;
Ja = zeros(height(matchesA), 1);
Jb = zeros(height(matchesB), 1);
for s = 1:num_secs
    Ia = matchesA.section == sec_nums(s);
    Ja(Ia) = cum_num_tiles(s) + matchesA.tile(Ia);
    
    Ib = matchesB.section == sec_nums(s);
    Jb(Ib) = cum_num_tiles(s) + matchesB.tile(Ib);
end

Ia = repmat((1:num_matches)', 3, 1);
Ib = repmat((1:num_matches)', 3, 1);

Ja = [Ja; Ja + 1; Ja + 2];
Jb = [Jb; Jb + 1; Jb + 2];

Sa = [double(matchesA.global_points(:)); ones(num_matches, 1)];
Sb = -[double(matchesA.global_points(:)); ones(num_matches, 1)];

m = num_matches;
n = total_tiles * 3;
nnzA = num_matches * 3;
nnzGamma = nnzA * 2;

A = sparse(Ia, Ja, S, m, n, nnzA);
gamma = sparse([Ia; Ib], [Ja; Jb], [Sa; Sb], m, n, nnzGamma);
b = reshape(Sa, num_matches, 3);
toc
tic;
params.lambda = 0.05;
x_hat = full((params.lambda .^ 2 * (A' * A) + gamma' * gamma) \ (params.lambda .^ 2 * A' * b));
toc