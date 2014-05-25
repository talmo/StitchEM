function tform = cpd_solve(ptsA, ptsB, varargin)
%CPD_SOLVE Aligns ptsB to ptsA using CPD.
% Usage:
%   tform = cpd_solve(ptsA, ptsB)
%   tform = cpd_solve(ptsA, ptsB, opt)
%   tform = cpd_solve(ptsA, ptsB, 'Name', Value)
%
% Parameters:
%   'method', 'affine': Transformation type. Can be 'rigid', 'affine', or
%       'nonrigid'.
%   'viz', false: displays visualization
%   'savegif', false: saves visualization into a gif
%   'verbosity', 0: outputs to console
%
% See also: align_z_pair_cpd, sp_lsq

% Default options
methods = {'rigid', 'affine', 'nonrigid'};
defaults.method = 'affine'; 
defaults.viz = false;
defaults.savegif = false;
defaults.verbosity = 0;

if nargin < 3
    opt = defaults;
else
    if isstruct(varargin{1})
        opt = varargin{1};
    else
        opt = struct(varargin{:});
    end
    
    % Use defaults for any missing options
    for f = fieldnames(defaults)'
        if ~isfield(opt, f{1})
            opt.(f{1}) = defaults.(f{1});
        end
    end
    opt.method = validatestring(opt.method, methods, mfilename);
end

if opt.verbosity > 0; fprintf('Calculating alignment using CPD (%s)...\n', opt.method); end
total_time = tic;

% Solve using CPD
cpd_tform = cpd_register(ptsA, ptsB, opt);

if instr(opt.method, {'rigid', 'affine'})
    tform = affine2d([[cpd_tform.s * cpd_tform.R'; cpd_tform.t'] [0 0 1]']);
elseif strcmp(opt.method, 'nonrigid')
    % TODO
    error('Nonrigid transform not yet implemented.')
end

if opt.verbosity > 0
    fprintf('Done. Error: <strong>%fpx / match</strong> [%.2fs]\n', rownorm2(tform.transformPointsForward(ptsB) - ptsA), toc(total_time))
end
end

