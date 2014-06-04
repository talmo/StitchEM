function show_sec_pair(secA, secB, blendmode)
%SHOW_SEC_PAIR Renders and displays a pair of sections.
% Usage:
%   show_sec_pair(secA, secB)
%   show_sec_pair(secA, secB, blendmode)
%
% Blend modes: 'falsecolor' (default), 'diff', 'blend'
%
% See also: show_sec, render_section

if nargin < 3
    blendmode = 'falsecolor';
end

[A, RA] = render_section(secA, 'z');
[B, RB] = render_section(secB, 'z');

imshowpair(A, RA, B, RB, blendmode)

end

