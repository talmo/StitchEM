function [secs, mean_error] = align_section_stack(secs, matchesA, matchesB, varargin)
%ALIGN_SECTION_STACK Calculates transforms to align a stack of sections.
% Usage:
%   [secs, mean_error] = ALIGN_SECTION_STACK(align_section_stack(secs, matchesA, matchesB)
%   ALIGN_SECTION_STACK(..., 'Name', 'Value')
%
% Notes:
%   - Use the name-value pairs to pass parameters on to the tikhonov
%   function, e.g., 'lambda'

% Process input
[params, unmatched_params] = parse_inputs(varargin{:});

% Calculate transforms
if params.sparse_solver
    [tforms, mean_error] = tikhonov_sparse(matchesA, matchesB, unmatched_params);
else
    [tforms, mean_error] = tikhonov(matchesA, matchesB, unmatched_params);
end

% Apply the calculated transforms to the rough tforms
for s = 1:size(tforms, 1)
    for t = 1:size(tforms, 2)
        if ~isempty(tforms{s, t})
            secs{s}.fine_tforms{t} = affine2d(secs{s}.rough_tforms{t}.T * tforms{s, t}.T);
        else
            secs{s}.fine_tforms{t} = secs{s}.rough_tforms{t};
        end
    end
end


end

function [params, unmatched] = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Use sparse solver
p.addParameter('sparse_solver', false);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;

end