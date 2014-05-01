function mean_registration_error = calculate_registration_error(fixed_inliers, moving_inliers, tform)
%CALCULATE_REGISTRATION_ERROR Applies a transform to the moving inliers and calculate the registration error.

registered_inliers = tform.transformPointsForward(moving_inliers);
registration_errors = calculate_match_distances(fixed_inliers, registered_inliers);
mean_registration_error = mean(registration_errors);

end

