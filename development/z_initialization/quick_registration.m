function [merge, fixed_padded, registered_padded, tform, mean_registered_distances] = quick_registration(fixed_sec_num, moving_sec_num, parameters)
%QUICK_REGISTRATION Register two sections with the given params and display the results.

% Testing
params.display_montage = true;
params.display_matches = true;
params.display_merge = true;

if nargin > 2
    params = overwrite_defaults(params, parameters);
end

% Register
[merge, fixed_padded, registered_padded, tform, mean_registered_distances] = feature_based_registration(fixed_sec_num, moving_sec_num, params);

% Calculate detected angle and translation
[theta, tx, ty, scale] = analyze_tform(tform);
fprintf('Transform Angle: %f, Translation: [%f, %f], Scale: %f\n', theta, tx, ty, scale)

end

