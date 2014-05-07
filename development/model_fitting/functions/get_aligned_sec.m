function sec = get_aligned_sec(sec_num)
%GET_ALIGNED_SEC Returns an XY aligned section.

%% Initialization
% Load images and such
sec = load_sec(sec_num, 'from_cache', false);

%% Rough alignment
% Register the tiles to their overviews
sec = rough_align_tiles(sec);

%% Detect features
sec = detect_section_features(sec, 'xy');

%% Match XY features
[matches.A, matches.B] = match_section_features(sec);

%% Solve XY alignment
tic;
% Build sparse matrices
[A, B] = matchmat(matches.A, matches.B);
% AT = BT
% (B - A)T = 0
% CT = 0
C = B - A;

% Deal with fixed tile
fixed_tile = 1;

% DT = F
j = 3 * fixed_tile - 2:3 * fixed_tile; % columns of fixed tile
F = -C(:, j); % fixed tile block column
D = C(:, setdiff(1:size(C, 2), j)); % C without F

% Solve
T = D \ F;

% Format into cell array of affine2d objects
Ts = mat2cell(full(T(:, 1:2)), repmat(3, length(T) / 3, 1));
rel_tforms = [{affine2d()}; cellfun(@(t) affine2d(t), Ts, 'UniformOutput', false)];

% Compose with rough tforms
tforms = cellfun(@(t1, t2) compose_tforms(t1, t2), sec.alignments.rough.tforms, rel_tforms, 'UniformOutput', false);

% Calculate residual and average error
res = full(D * T - F);
avg_error = rownorm2(res(:, 1:2));

% Calculate error before alignment
res_before = full(D - F);
avg_error_before = rownorm2(res_before(:, 1:2));

fprintf('Error: %f -> %fpx / match [%.2fs]\n', avg_error_before, avg_error, toc)

% Legacy
sec.xy_tforms = tforms;

% Save to section structure
xy.tforms = tforms;
xy.rel_tforms = rel_tforms; % relative to rough
xy.rel_to = 'rough';
xy.meta.fixed_tile = fixed_tile;
xy.meta.avg_error_before = avg_error_before;
xy.meta.avg_error_after = avg_error;
sec.alignments.xy = xy;
end

