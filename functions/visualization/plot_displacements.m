function plot_displacements(ptsA, ptsB, varargin)
%PLOT_DISPLACEMENTS Plots match displacements with their geometric median.
%
% Usage:
%   plot_displacements(displacements)
%   plot_displacements(matches)
%   plot_displacements(ptsA, ptsB)
%   plot_displacements(..., mode)
%   plot_displacements(..., 'Name',Value)
%
% Args:
%   displacements: valid set of points
%   matches: match structure with A and B fields containing feature tables
%       or matching point sets.
%       If the fields are tables, they must contain a global_points column.
%   ptsA, ptsB: valid sets of matching points
%   mode: plot displacements for 'inliers', 'outliers', or 'both' (default)
%       Only applicable when a match structure is specified that contains
%       an outliers field.
%
% Parameters:
%   'MarkerSpec', 'ko' linespec of all displacements
%   'InlierSpec', 'gx': linespec of inlier displacements
%   'geomedian', true: plot the geometric median of all displacements
%   'geomedianSpec', 'r*': linespec of geometric median point
%
% See also: plot_matches

outD = [];
if isstruct(ptsA)
    matches = ptsA;
    if ~isfield(matches, 'A') || ~isfield(matches, 'B')
        error('Invalid match structure specified. The structure must have ''A'' and ''B'' fields.')
    end

    % Inlier displacements
    if istable(matches.A) && istable(matches.B)
        inD = matches.B.global_points - matches.A.global_points;
    else
        mA = validatepoints(matches.A);
        mB = validatepoints(matches.B);
        inD = mB - mA;
    end

    % Outlier displacements
    if isfield(matches, 'outliers')
        if istable(matches.outliers.A) && istable(matches.outliers.B)
            outD = matches.outliers.B.global_points - matches.outliers.A.global_points;
        else
            mA = validatepoints(matches.outliers.A);
            mB = validatepoints(matches.outliers.B);
            outD = mB - mA;
        end
    end
    
    if nargin > 1; varargin = [{ptsB} varargin]; end
else
    ptsA = validatepoints(ptsA);
    
    % Assume ptsA is a displacements array
    inD = ptsA;
    if nargin > 1
        % Check if ptsB is a points array
        try
            ptsB = validatepoints(ptsB);
            inD = ptsB - ptsA;
        catch
            varargin = [{ptsB} varargin];
        end
    end
end

% Process parameters
params = parse_inputs(varargin{:});

% Combine displacements
D = [inD; outD];

% Save initial hold state
hold_state = get_hold_state();

% Plot displacements
switch params.mode
    case 'inliers'
        plot(inD(:,1), inD(:,2), params.MarkerSpec)
    case 'outliers'
        plot(outD(:,1), outD(:,2), params.MarkerSpec)
    case 'both'
        plot(D(:,1), D(:,2), params.MarkerSpec)
        
        if ~isempty(params.InlierSpec)
            hold on
            plot(inD(:,1), inD(:,2), params.InlierSpec)
        end
end

% Geometric median
if params.geomedian
    gm = geomedian(D);
    hold on
    plot(gm(1), gm(2), params.geomedianSpec)
end

% Adjust plot
axis equal
grid on
%title(['\bfDisplacements\rm: ' sprintf('n = %d/%d inliers', size(inD, 1), size(D, 1))])
title(sprintf('\\bfDisplacements\\rm: n = %d/%d inliers', size(inD, 1), size(D, 1)))
xlabel('\deltaX')
ylabel('\deltaY')

% Restore initial hold state
hold(hold_state)

end

function params = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;

% Which displacements to plot
modes = {'inliers', 'outliers', 'both'};
p.addOptional('mode', 'both', @(x) validatestr(x, modes));

% Marker style
p.addParameter('MarkerSpec', 'ko');

% Additional marker to indicate inliers
p.addParameter('InlierSpec', 'gx');

% Geometric median
p.addParameter('geomedian', true);
p.addParameter('geomedianSpec', 'r*');

% Validate and parse input
p.parse(varargin{:});
params = p.Results;

end