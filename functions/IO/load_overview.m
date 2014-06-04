function sec = load_overview(sec, scale)
%LOAD_OVERVIEW Loads the overview image of a section at the specified scale.
% Usage:
%   sec = load_overview(sec, scale)

load_time = tic;

overview_path = get_overview_path(sec);

sec.overview.img = imread(overview_path);
sec.overview.path = overview_path;
sec.overview.size = size(sec.overview.img); % get unscaled size
sec.overview.scale = scale;
sec.overview.alignment.tform = affine2d();
sec.overview.alignment.rel_to_sec = sec.num;

fprintf('Loaded overview (%sx) in %s. [%.2fs]\n', num2str(scale), sec.name, toc(load_time))

end

