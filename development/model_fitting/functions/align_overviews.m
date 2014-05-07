function overview_alignment = align_overviews(secA, secB, varargin)
%ALIGN_OVERVIEWS Aligns the overview of one section to another (secB to secA).
% Usage:
%   secB.overview.alignment = align_overviews(secA, secB)

registration_time = tic;
%% Register overviews
% Parse inputs
[params, unmatched_params] = parse_input(varargin{:});

if params.verbosity > 0
    fprintf('== Aligning overview of section %d to section %d.\n', secB.num, secA.num)
end

% Preprocess the images (resize, crop, filter)
filteredA = pre_process(secA, params);
filteredB = pre_process(secB, params);

% Register overviews
[rel_tform, ~, ~, mean_registration_error] = surf_register(filteredA, filteredB, unmatched_params);

% Compose with tform of relative section
base_tform = secA.overview.alignment.tform;
tform = compose_tforms(base_tform, rel_tform);

% Save to output structure
overview_alignment.tform = tform;
overview_alignment.rel_tform = rel_tform;
overview_alignment.rel_to_sec = secA.num;

if params.verbosity > 0
    fprintf('Done aligning overviews. Mean error = %.2fpx [%.2fs]\n', mean_registration_error, toc(registration_time))
end

end

function img = pre_process(sec, params)
% Pre-processes the overview image for a section.

img = sec.overview.img;

% Resize to detection scale
if sec.overview.scale ~= params.detection_scale
    img = imresize(img, (1 / sec.overview.scale) * params.detection_scale);
end

% Crop to center
img = imcrop(img, [size(img, 2) * (params.crop_ratio / 2), size(img, 1) * (params.crop_ratio / 2), size(img, 2) * params.crop_ratio, size(img, 1) * params.crop_ratio]);

% Apply median filter
if params.median_filter_radius > 0
    img = medfilt2(img, [params.median_filter_radius params.median_filter_radius]);
end

end

function [params, unmatched] = parse_input(varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Pre-processing
p.addParameter('detection_scale', 0.78);
p.addParameter('crop_ratio', 0.5);

% Image filtering
p.addParameter('median_filter_radius', 6);

% Verbosity
p.addParameter('verbosity', 1);

% Visualization
p.addParameter('show_registration', false);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;

end