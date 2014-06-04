function p = params_struct(p, param_name, defaults)
%PARAMS_STRUCT Adds a structure and its fields to the inputParser instance.
% Usage:
%   p = struct_params(p, param_name, defaults)
% 
% See also: overwrite_struct

% Add structure as a parameter
p.addParameter(param_name, defaults, @(x) isstruct(x) && all(instr(fieldnames(x), fieldnames(defaults), 'a')));

% Add each field in the structure as parameter
for f = fieldnames(defaults)'
    p.addParameter(f{1}, defaults.(f{1}));
end

end

