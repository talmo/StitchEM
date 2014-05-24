function params = overwrite_struct(params, defaults, struct_field, UsingDefaults)
%OVERWRITE_STRUCT Overwrites the defaults of a structure field.
% Usage:
%   params = overwrite_struct(params, defaults, struct_field, UsingDefaults)

% Overwrite struct values if params passed explicitly
for f = fieldnames(defaults)'
    if ~instr(f{1}, fieldnames(params.(struct_field)))
        params.(struct_field).(f{1}) = defaults.(f{1});
    end
    if ~instr(f{1}, UsingDefaults)
        params.(struct_field).(f{1}) = params.(f{1});
    end
    
    % Keep the "official copy" of the params in the structure to avoid ambiguity
    params = rmfield(params, f{1});
end

end

