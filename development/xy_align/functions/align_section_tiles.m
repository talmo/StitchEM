function [sec, mean_error] = align_section_tiles(sec, matchesA, matchesB, varargin)
%ALIGN_SECTION_TILES Calculates transforms to align tiles of a section.

% Process input
[params, unmatched_params] = parse_inputs(varargin{:});

% Calculate transforms
[tforms, mean_error] = tikhonov(matchesA, matchesB, unmatched_params);

% Apply the calculated transforms to the rough tforms
for t = 1:size(tforms, 2)
    if ~isempty(tforms{s, t})
        sec.fine_alignments{t} = affine2d(sec.rough_alignments{t}.T * tforms{1, t}.T);
    else
        sec.fine_alignments{t} = sec.rough_alignments{t};
    end
end

end

function [params, unmatched] = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Debugging
% p.addParameter('show_summary', false);
% 
% % Visualization
% p.addParameter('show_merge', false);
% p.addParameter('show_matches', false);
% p.addParameter('render_merge', false);
% p.addParameter('display_scale', 0.025);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;

end