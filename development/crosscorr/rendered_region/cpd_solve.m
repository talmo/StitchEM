function tform = cpd_solve(ptsA, ptsB, method, visualize)
%CPD_SOLVE Aligns ptsB to ptsA using CPD.
% Usage:
%   tform = cpd_solve(ptsA, ptsB)
%   tform = cpd_solve(ptsA, ptsB, method)
%   tform = cpd_solve(ptsA, ptsB, method, visualize)
%
% Methods are: 'rigid', 'affine', or 'nonrigid'

if nargin < 3
    method = 'affine';
end
if nargin < 4
    visualize = false;
end

% CPD options
methods = {'rigid', 'affine', 'nonrigid'};
opt.method = validatestring(method, methods, mfilename); 
opt.viz = visualize;
opt.savegif = false;
opt.verbosity = 0;

fprintf('Calculating alignment using CPD (%s)...\n', opt.method)
total_time = tic;

% Solve using CPD
cpd_tform = cpd_register(ptsA, ptsB, opt);

if instr(method, {'rigid', 'affine'})
    tform = affine2d([[cpd_tform.s * cpd_tform.R'; cpd_tform.t'] [0 0 1]']);
elseif strcmp(method, 'nonrigid')
    % TODO
    error('Nonrigid transform not yet implemented.')
end

fprintf('Done. Error: <strong>%fpx / match</strong> [%.2fs]\n', rownorm2(tform.transformPointsForward(ptsB) - ptsA), toc(total_time))

end

