%% Reference:
%   cpd_register
%   cpd_GRBF
%   cpd_G
%   cpd_GRBF_lowrank
%   cpd_GRBF_lowrankQS
%   cpd_transform
%   CPDNonRigid

%% Initialize
% Points
matches = secB.corr_matches;
ptsA = matches.A.global_points;
ptsB = matches.B.global_points;

% Align
tform = cpd_solve(ptsA, ptsB, 'method', 'nonrigid');

%% Transform parameters
% Original points
Y = tform.Yorig; % n x 2
n = size(Y, 1);

% Gaussian smoothing filter size (denormalized)
beta = tform.beta; % scalar

% Non-rigid coefficient
W = tform.W; % n x 2

% Scaling denormalization
s = tform.s; % scalar

% Translation denormalization
shift = tform.shift; % 1 x 2

% Gaussian parameter
k = -2 * beta ^ 2; % scalar

% Test points (m x 2)
%X = ptsA;
X = ones(1e3, 2);
%X = rand(1e3, 2);
m = size(X, 1);

%% Sanity check
% tform
Y1 = tform.transformPointsInverse(X);

% Equation
G = tform.findG(X);
Y2 = X * s + G * W + repmat(shift, size(X, 1), 1);

assert(isequal(Y1, Y2))
%% Computing G full
G_control = tform.findG(X); % m x n

% Matrix form
    % (m, 2, n)          % (m, 2, n)    % (n, 2, m)
G = repmat(X, [1 1 n]) - permute(repmat(Y, [1 1 m]), [3 2 1]);
G = reshape(sum(G .^ 2, 2), m, n) / k;
G = exp(G);

assert(isequal(G, G_control), 'G ~= G_control')

%% FGT
Y1 = G * W; % == [G * W(:,1), G * W(:,2)]

e          = 8;      % Ratio of far field (default e = 10)
K          = round(min([sqrt(n) 100])); % Number of centers (default K = sqrt(Nx))
p          = 6;      % Order of truncation (default p = 8)
hsigma = sqrt(2)*beta;
[xc1 , A_k1] = fgt_model(Y', W(:, 1)', hsigma, e);
[xc2 , A_k2] = fgt_model(Y', W(:, 2)', hsigma, e);
Y2 = [fgt_predict(X' , xc1 , A_k1 , hsigma, e)', ...
      fgt_predict(X' , xc2 , A_k2 , hsigma, e)'];

rownorm2(Y1 - Y2)

%% FGT testing
clear tform
X = ones(1e6, 2);
tform = cpd_solve(ptsA, ptsB, 'method', 'nonrigid', 'tform_method', 'fgt');

% full
tic;
tform.mode = 'full';
Y1 = tform.transformPointsInverse(X);
fprintf('full: %fs\n', toc)

% parblock
tic;
tform.mode = 'parblock';
tform.block_sz = 1e5;
Y2 = tform.transformPointsInverse(X);
fprintf('parblock: %fs\n', toc)

% fgt
tic;
tform.mode = 'fgt';
Y3 = tform.transformPointsInverse(X);
fprintf('fgt: %fs | error = %f px/match\n', toc, rownorm2(Y3 - Y2))