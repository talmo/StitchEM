function TF = validatestring_regexp(str, expression, varargin)
%VALIDATESTRING_REGEXP Checks the validity of a text string using regexp.
% Usage:
%   TF = validatestring_regexp(str, expression)
%   TF = validatestring_regexp(str, expression, 'ThrowError', true)
%   TF = validatestring_regexp(..., option1, ..., optionN)
%
% Set ThrowError to true to throw error if string does not match.
% See regexp for option names.
%
% See also: regexp, validatestr, validatestring, instr

% Process parameters
[params, unmatched_params] = parse_input(varargin{:});

regexp_options = {'all', 'once', 'matchcase', 'ignorecase', 'noemptymatch', 'emptymatch', 'dotall', 'dotexceptnewline', 'stringanchors', 'lineanchors', 'literalspacing', 'freespacing'};

end

