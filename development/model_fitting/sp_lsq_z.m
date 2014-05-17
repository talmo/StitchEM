% Load a Z aligned stack first (need the Z matches)

%% Merge all Z matches using XY alignment
matches.A = table();
matches.B = table();

for s = 2:length(secs)
    secA = secs{s - 1};
    secB = secs{s};
    
    % Get Z matches
    sec_matches.A = secB.z_matches.A;
    sec_matches.B = secB.z_matches.B;
    
    % Use XY alignment for global
    tformsA = secA.alignments.xy.tforms;
    tformsB = secB.alignments.xy.tforms;
    for t = 1:length(tformsA)
        idx = sec_matches.A.tile == t;
        sec_matches.A.global_points(idx, :) = tformsA{t}.transformPointsForward(sec_matches.A.local_points(idx, :));
    end
    for t = 1:length(tformsB)
        idx = sec_matches.B.tile == t;
        sec_matches.B.global_points(idx, :) = tformsB{t}.transformPointsForward(sec_matches.B.local_points(idx, :));
    end
    
    % Save back to secs
    secB.z_matches.A = sec_matches.A;
    secB.z_matches.B = sec_matches.B;
    secs{s} = secB;
    
    % Hack so matchmat produces correct sparse matrix
    sec_matches.A.tile = repmat(s - 1, height(sec_matches.A), 1);
    sec_matches.B.tile = repmat(s, height(sec_matches.B), 1);
    
    % Merge with large table
    matches.A = [matches.A; sec_matches.A];
    matches.B = [matches.B; sec_matches.B];
end

% Hack so matchmat produces correct sparse matrix
matches.A.section = ones(height(matches.A), 1);
matches.B.section = ones(height(matches.B), 1);

%% Solve
tic
fixed_sec = 1;
[rel_tforms, avg_prior_error, avg_post_error] = sp_lsq(matches, fixed_sec);
num_matches = height(matches.A);
fprintf('Error: %f -> <strong>%fpx / match</strong> (%d matches) [%.2fs]\n', avg_prior_error, avg_post_error, num_matches, toc)

%% Save back to secs structure
for s = 2:length(secs)
    % Create alignment relative to XY
    alignment.rel_tforms = repmat(rel_tforms(s), size(secs{s}.alignments.xy.tforms));
    alignment.rel_to = 'xy';
    alignment.tforms = compose_tforms(secs{s}.alignments.xy.tforms, alignment.rel_tforms);
    alignment.method = 'sp_lsq_z';
    
    % Calculate errors
    prior_error = rownorm2(secs{s}.z_matches.B.global_points - rel_tforms{s - 1}.transformPointsForward(secs{s}.z_matches.A.global_points));
    post_error = rownorm2(rel_tforms{s}.transformPointsForward(secs{s}.z_matches.B.global_points) - rel_tforms{s - 1}.transformPointsForward(secs{s}.z_matches.A.global_points));
    
    alignment.meta.avg_prior_error = prior_error;
    alignment.meta.avg_post_error = post_error;
    
    secs{s}.alignments.z = alignment;
end