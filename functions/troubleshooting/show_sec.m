function show_sec(sec, alignment, scale)
%SHOW_SEC Renders and displays a section.
% Usage:
%   show_sec(sec)
%   show_sec(sec, alignment)
%   show_sec(sec, alignment, scale)
%
% See also: render_section

% Alignment
if nargin < 2
    alignments = fieldnames(sec.alignments);
    alignment = alignments{end};
end
[~, alignment_name] = validatealignment(alignment, sec);

% Scale
if nargin < 3
    scale = 0.050;
end

% Render
[rendered, R] = render_section(sec, alignment, 'scale', scale);

% Show
figure
imshow(rendered, R)

% Adjust figure
title_str = sprintf('\\bfSection\\rm: %s (%sx) | \\bfAlignment\\rm: %s', sec.name, num2str(scale), alignment_name);
if isfield(alignment, 'meta') && isfield(alignment.meta, 'avg_post_error')
    title_str = sprintf('%s | \\bfError\\rm: %.3f px/match', title_str, alignment.meta.avg_post_error);
end
append_title(strrep(title_str, '_', '\_'))
ax2int()

end

