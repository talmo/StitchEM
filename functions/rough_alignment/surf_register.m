function [tform, fixed_inliers, moving_inliers, mean_registration_error] = surf_register(fixed_img, moving_img, varargin)
%SURF_REGISTER Estimates a transformation to register two images.

% Parse inputs
[fixed_img, moving_img, params] = parse_inputs(fixed_img, moving_img, varargin{:});

%% Detection and matching
% Get points
tic;
[fixed_pts, fixed_desc] = get_feats(fixed_img, params);
[moving_pts, moving_desc] = get_feats(moving_img, params);
SURF_time = toc;
if params.verbosity > 0
    fprintf('Found %d and %d features. [%.2fs]\n', size(fixed_pts, 1), size(moving_pts, 1), SURF_time)
end

% Match using NNR
tic;
match_indices = matchFeatures(fixed_desc, moving_desc, ...
    'MatchThreshold', params.NNR_MatchThreshold, ...
    'Method', params.NNR_Method, ...
    'Metric', params.NNR_Metric, ...
    'MaxRatio', params.NNR_MaxRatio);

% Get the points corresponding to the matched features
fixed_matching_pts = fixed_pts(match_indices(:, 1), :);
moving_matching_pts = moving_pts(match_indices(:, 2), :);
NNR_time = toc;
num_potential_matches = size(fixed_matching_pts, 1);

if params.verbosity > 0
    fprintf('Found %d potentially matching features. [%.2fs]\n', num_potential_matches, NNR_time)
end

% Check for too few potential matches
if num_potential_matches < params.min_potential_matches
    msg_id = 'surf_register:notEnoughPotentialMatches';
    msg = sprintf('Less than %d potential matches were detected. The registration may not be reliable.\n', ...
        params.min_potential_matches);
    
    if params.suppress_few_potential_matches_error
        if params.verbosity > 0
            warning(msg_id, msg);
        end
    else
        error(msg_id, msg);
    end
end

%% Transform estimation
% Find inliers and calculate transform
tic;
[tform, moving_inliers, fixed_inliers] = estimateGeometricTransform(moving_matching_pts, fixed_matching_pts, ...
    params.MSAC_transformType, 'MaxNumTrials', params.MSAC_MaxNumTrials, 'Confidence', params.MSAC_Confidence, 'MaxDistance', params.MSAC_MaxDistance);
tform_estimation_time = toc;
num_inliers = size(fixed_inliers, 1);

% Calculate error
mean_registration_error = calculate_registration_error(fixed_inliers, moving_inliers, tform);

if params.verbosity > 0
    fprintf('Found %d inliers within matches and estimated registration transform. [%.2fs]\n', num_inliers, tform_estimation_time)
    fprintf('Registration error: %.2fpx\n', mean_registration_error);
end

% Check for too few inliers
if size(fixed_inliers, 1) < params.min_inliers
    [scale, rotation, translation] = estimate_tform_params(tform);
    msg_id = 'surf_register:notEnoughInliers';
    msg = sprintf(['Less than %d inliers were detected. The registration may not be reliable.\n' ...
        '\tComputed transform: Scale = %f | Rotation = %f | Translation = [%f %f]'], params.min_inliers, scale, rotation, translation(1), translation(2));
    
    if params.suppress_few_inliers_error
        warning(msg_id, msg);
    else
        error(msg_id, msg);
    end
end

end

function [points, descriptors] = get_feats(img, params)
% Find interest points
interest_points = detectSURFFeatures(img, ...
    'MetricThreshold', params.SURF_MetricThreshold, ...
    'NumOctaves', params.SURF_NumOctaves, ...
    'NumScaleLevels', params.SURF_NumScaleLevels);

% Get descriptors from pixels around interest points
[descriptors, valid_points] = extractFeatures(img, ...
    interest_points, ...
    'SURFSize', params.SURFSize);

% Save valid points
points = valid_points(:).Location;

end

function [fixed_img, moving_img, params] = parse_inputs(fixed_img, moving_img, varargin)
% Profiles overwrite the default parameters, but any explictly inputted
% name-value pair will overwrite these
profiles.default = {};
profiles.debug = {'verbosity', 1, 'suppress_few_potential_matches_error', false};
profiles.fallback1 = {'NNR_MatchThreshold', 0.9, 'MSAC_MaxNumTrials', 1500, 'MSAC_Confidence', 95, 'suppress_few_potential_matches_error', false, 'verbosity', 1};
profiles.fallback2 = {'NNR_MatchThreshold', 0.8, 'MSAC_MaxNumTrials', 2000, 'MSAC_Confidence', 95, 'suppress_few_potential_matches_error', false, 'verbosity', 1};

% Create inputParser instance for first round of parsing (profiles)
p1 = inputParser;
p1.KeepUnmatched = true;

% Required parameters
p1.addRequired('fixed_img');
p1.addRequired('moving_img');

% Optional profile for registration parameters
p1.addOptional('profile', 'default', @(x) any(ismember(fieldnames(profiles), x)));

% Validate and parse input
p1.parse(fixed_img, moving_img, varargin{:});
fixed_img = p1.Results.fixed_img;
moving_img = p1.Results.moving_img;
profile_args = profiles.(p1.Results.profile);
custom_args = p1.Unmatched;

% Create inputParser instance for second round of parsing
p2 = inputParser;

% Detection
p2.addParameter('SURF_MetricThreshold', 1000); % MATLAB default = 1000
p2.addParameter('SURF_NumOctaves', 3); % MATLAB default = 3
p2.addParameter('SURF_NumScaleLevels', 4); % MATLAB default = 4
p2.addParameter('SURFSize', 64); % MATLAB default = 64

% Matching
p2.addParameter('NNR_Method', 'NearestNeighborRatio'); % MATLAB default = 'NearestNeighborRatio'
p2.addParameter('NNR_Metric', 'SSD'); % MATLAB default = 'SSD'
p2.addParameter('NNR_MatchThreshold', 1.0); % MATLAB default = 1.0
p2.addParameter('NNR_MaxRatio', 0.6); % MATLAB default = 0.6

% Transform estimation
p2.addParameter('MSAC_transformType', 'similarity'); % MATLAB default = 'similarity'
p2.addParameter('MSAC_MaxNumTrials', 1000); % MATLAB default = 1000
p2.addParameter('MSAC_Confidence', 99); % MATLAB default = 99
p2.addParameter('MSAC_MaxDistance', 1.5); % MATLAB default = 1.5

% Bad registration detection
p2.addParameter('suppress_few_potential_matches_error', true);
p2.addParameter('min_potential_matches', 30);
p2.addParameter('suppress_few_inliers_error', false);
p2.addParameter('min_inliers', 5);

% Debugging
p2.addParameter('verbosity', 0);

% Validate and parse input
p2.parse(profile_args{:}, custom_args);
params = p2.Results;
end