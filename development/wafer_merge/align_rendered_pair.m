function alignment = align_rendered_pair(secA, alignmentA, secB, alignmentB, varargin)
%ALIGN_RENDERED_PAIR Aligns a pair of sections after rendering them.
% Usage:
%   alignment = align_rendered_pair(secA, alignmentA, secB, alignmentB)

% Parameters
params.render_scale = 0.075;
params.detection_scale = 0.075;
params.MetricThreshold = 7500;
params.CLAHE = true;
params.CLAHE_tiles = [8, 8];

% Render
[A, RA] = render_section(secA, alignmentA, 'scale', params.render_scale);
%A = imresize(A, params.render_scale);
[B, RB] = render_section(secB, alignmentB, 'scale', params.render_scale);
%B = imresize(B, params.render_scale);

% CLAHE
if params.CLAHE
    A = adapthisteq(A, 'NumTiles', params.CLAHE_tiles);
    B = adapthisteq(B, 'NumTiles', params.CLAHE_tiles);
end

% Detect features
featsA = detect_surf_features(A, 'MetricThreshold', params.MetricThreshold, 'pre_scale', params.render_scale, 'detection_scale', params.detection_scale);
featsB = detect_surf_features(B, 'MetricThreshold', params.MetricThreshold, 'pre_scale', params.render_scale, 'detection_scale', params.detection_scale);
fprintf('Detected <strong>%d</strong> and <strong>%d</strong> features (at %sx).\n', height(featsA), height(featsB), num2str(params.detection_scale))

% Global points
[featsA.global_points(:,1), featsA.global_points(:,2)] = RA.intrinsicToWorld(featsA.local_points(:,1) * params.render_scale, featsA.local_points(:,2) * params.render_scale);
[featsB.global_points(:,1), featsB.global_points(:,2)] = RB.intrinsicToWorld(featsB.local_points(:,1) * params.render_scale, featsB.local_points(:,2) * params.render_scale);

% Match
nnr_matches = nnr_match(featsA, featsB, 'out', 'rows-nodesc');

% Filter
[inliers, outliers] = gmm_filter(nnr_matches);
matches.A = nnr_matches.A(inliers, :);
matches.B = nnr_matches.B(inliers, :);
matches.outliers.A = nnr_matches.A(outliers, :);
matches.outliers.B = nnr_matches.B(outliers, :);
fprintf('Found <strong>%d/%d</strong> matches. Error: <strong>%f px/match</strong>\n', height(matches.A), height(nnr_matches.A), rownorm2(matches.B.global_points - matches.A.global_points))

% Align
alignment = align_z_pair_cpd(secB, matches, alignmentB);

end

