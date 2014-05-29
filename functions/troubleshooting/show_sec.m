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

% Scale
if nargin < 3
    scale = 0.075;
end

% Render
[rendered, R] = render_section(sec, alignment, 'scale', scale);

% Show
figure
imshow(rendered, R)
title(strrep(sprintf('\\bf%s\\rm (%sx)', sec.name, num2str(scale)), '_', '\_'))
if ischar(alignment)
    append_title(strrep(sprintf('\\bfAlignment\\rm: %s', alignment), '_', '\_'))
end
end

