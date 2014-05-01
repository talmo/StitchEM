function TF = instr(needle, haystack, flags)
%INSTR Returns true if needle is in haystack, where either are strings or cell arrays of strings.
%
% Usage:
%   TF = instr(char, char)
%   TF = instr(char, cellstr)
%   TF = instr(cellstr, char)
%   TF = instr(cellstr, cellstr)
%   TF = instr(..., flags)
%
% Args:
%   needle and haystack are strings or cell strings.
%   flags can be any combination of:
%       'i' => Case-insensitive
%       's' => Matches if needle is a substring of haystack
%       'r' => Tests regular expressions in needle
%       Defaults to 's'.
%
% See also: strcmp, strfind, validatestr

% Parse input
default_flags = 's';
all_flags = 'isr';
if ischar(needle) && ischar(haystack); default_flags = 's'; end
if nargin < 3; flags = default_flags; end
p = inputParser;
p.addRequired('s1', @(x) ischar(x) || iscellstr(x));
p.addRequired('s2', @(x) ischar(x) || iscellstr(x));
p.addOptional('flags', default_flags, @(x) isempty(x) || (ischar(x) && all(arrayfun(@(c) ~isempty(strfind(all_flags, c)), x))));
p.parse(needle, haystack, lower(flags));
needle = p.Results.s1;
haystack = p.Results.s2;
flags = p.Results.flags;

% Parse flags
regex = any(flags == 'r');
substr = any(flags == 's');
case_insensitive = any(flags == 'i');

% Figure out matching function
if regex
    case_sens = 'matchcase'; if case_insensitive; case_sens = 'ignorecase'; end
    f = @(str, expression) ~cellfun('isempty', regexp(str, expression, case_sens));
elseif substr
    if case_insensitive
        f = @(str, pattern) ~cellfun('isempty', strfind(lower(str), lower(pattern)));
    else
        f = @(str, pattern) ~cellfun('isempty', strfind(str, pattern));
    end
else
    if case_insensitive
        f = @strcmpi;
    else
        f = @strcmp;
    end
end

% Make sure inputs are cell strings
if ~iscellstr(needle); needle = {needle}; end
if ~iscellstr(haystack); haystack = {haystack}; end

% Match
for i = 1:numel(needle)
    % Look for s1{i} in s2
    TF = any(f(haystack, needle{i}));

    % Return if we find any s1 in s2
    if TF; return; end
end
end

