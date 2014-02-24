%% Load stage stitched images

sec1 = imread('~/EMdata/W002/S2-W002_Sec1_Montage/StageStitched_S2-W002_sec1.tif');
sec2 = imread('~/EMdata/W002/S2-W002_Sec2_Montage/StageStitched_S2-W002_sec2.tif');

%% Show montage (side-by-side)
figure, imshowpair(sec1, sec2, 'montage')

%% Show overlay
figure, imshowpair(sec1, sec2)

%% Default settings
[optimizer, metric] = imregconfig('monomodal');

tic;
sec1_registered = imregister(sec1, sec2, 'rigid', optimizer, metric, 'DisplayOptimization', true);
toc
figure, imshowpair(sec1_registered, sec2)
% Almost no change from original

%% Monomodal optimizer
[optimizer, metric] = imregconfig('monomodal');

% Monomodal parameters (RegularStepGradientDescent)
optimizer.GradientMagnitudeTolerance = 1e-4; % default = 1e-4
optimizer.MinimumStepLength = 64*1e-5; % default = 1e-5
optimizer.MaximumStepLength = 64*0.0625; % default = 0.0625
optimizer.MaximumIterations = 50; % default = 100
optimizer.RelaxationFactor = 0.1; % default = 0.5

pyramid_levels = 4; % default = 3

tic;
sec1_registered = imregister(sec1, sec2, 'rigid', optimizer, metric, 'DisplayOptimization', true, 'PyramidLevels', pyramid_levels);
toc
figure, imshowpair(sec1_registered, sec2)

%% Multimodal optimizer
[optimizer, metric] = imregconfig('multimodal');

% Multimodal parameters (OnePlusOneEvolutionary)
optimizer.GrowthFactor = 1e3; % default = 1.05
optimizer.Epsilon = 1.5e-6; % default = 1.5e-6
optimizer.InitialRadius = 1.0e-2; % default = 6.25e-3
optimizer.MaximumIterations = 50; % default = 100

pyramid_levels = 3; % default = 3

tic;
sec1_registered = imregister(sec1, sec2, 'rigid', optimizer, metric, 'DisplayOptimization', true, 'PyramidLevels', pyramid_levels);
toc
figure, imshowpair(sec1_registered, sec2)

