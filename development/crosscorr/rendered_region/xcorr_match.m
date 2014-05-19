function [ptsA, ptsB] = xcorr_match(A, R_A, B, R_B, varargin)
%XCORR_MATCH Finds matches in a grid between A and B.
% Usage:
%   tform = xcorr_align(A, B)
%   tform = xcorr_align(A, R_A, B, R_B)

if ~isa(R_A, 'imref2d')
    if nargin > 3
        varargin = [{R_B} varargin];
    end
    if nargin > 2
        varargin = [{B} varargin];
    end
    
    B = R_A;
    R_A = imref2d(size(A));
    R_B = imref2d(size(B));
end

% Process parameters
[params, unmatched_params] = parse_input(varargin{:});

% Estimate base A -> B offset
A_loc = [R_A.YWorldLimits(1), R_A.XWorldLimits(1)];
B_loc = [R_B.YWorldLimits(1), R_B.XWorldLimits(1)];
base_offset = A_loc - B_loc;

% Create block grid
[rows, cols] = meshgrid(1:params.grid_sz(1):size(B, 1), 1:params.grid_sz(2):size(B, 2));
locations = [rows(:), cols(:)];

% Initialize containers
offsets = NaN(size(locations));
corrs = NaN(length(locations), 1);

% Do cross correlation on each block
if params.verbosity > 0
    fprintf('Finding cross-correlation in %d regions...\n', length(locations));
    xcorr_time = tic;
end
parfor i = 1:length(locations)
    % Extract block from B
    loc = locations(i, :);
    block = B(loc(1):min(loc(1)+params.block_sz(1)-1, size(B, 1)), ...
              loc(2):min(loc(2)+params.block_sz(2)-1, size(B, 2)));
          
    % Skip this block if it has no variation
    if std(double(block(:))) == 0
        continue
    end
    
    % Find the normalized cross correlation
    C = normxcorr2(block, A);
    
    % Find the peak of correlation
    if params.subpixel_peak
        [peakJ, peakI, peak_corr] = findpeak(C, true);
    else
        [peak_corr, peak_idx] = max(C(:));
        [peakI, peakJ] = ind2sub(size(C), peak_idx);
    end
    
    % Calculate the offset from A
    offset = [peakI, peakJ] - size(block);
    corrs(i) = peak_corr;
    offsets(i, :) = base_offset + offset - loc + [1, 1];
end

not_nan = ~isnan(corrs);

% Convert to XY coordinates
ptsA = fliplr(locations(not_nan, :));
ptsB = fliplr(locations(not_nan, :) - offsets(not_nan, :));

if params.verbosity > 1
    mean_corr = mean(corrs(not_nan));
    mean_offset = mean(offsets(not_nan, :));
    fprintf('Mean correlation: %f\n', mean_corr)
    fprintf('Mean offset: [%f, %f]\n', mean_offset)
end

if params.verbosity > 0
    fprintf('Done. Error: <strong>%fpx / match</strong> [%.2fs]\n', rownorm2(ptsB - ptsA), toc(xcorr_time))
end

end

function [params, unmatched] = parse_input(varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Spacing between each block in the grid
p.addParameter('grid_sz', [50, 50])

% Size of each block
p.addParameter('block_sz', [100, 100])

% Find subpixel peak correlation coordinate
p.addParameter('subpixel_peak', true)

% Verbosity
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;

end