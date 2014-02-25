%% Get transforms for some sections
% Parameters
params.median_filter = true;
params.median_filter_radius = 6; % default = 3
params.display_montage = false;
params.display_matches = false;
params.display_merge = false;

% Initialize
sec_nums = 1:10;
transforms = cell(length(sec_nums), 1);

% Register the sections
for i = 1:length(sec_nums)
    fprintf('Registering section %d...\n', sec_nums(i)), tic;
    [~, ~, ~, tform, ~] = feature_based_registration(sec_nums(i), sec_nums(i) + 1, params);
    transforms{i} = tform;
    fprintf('Done. [Total: %.2fs]\n\n', toc)
end
