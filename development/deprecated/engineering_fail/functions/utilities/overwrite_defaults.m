function parameters = overwrite_defaults(defaults, new_parameters)
%OVERWRITE_PARAMETERS Overwrites fields of a structure with any matching fields in the new structure.
% Replaces up to 3 nested levels of parameters (sub-sub-fields).

% Start with the default parameters
parameters = defaults;

% Loop through each field of the new parameters
f = fieldnames(new_parameters); % fields
for i = 1:length(f)
    
    if isstruct(new_parameters.(f{i})) % nested level 1
        
        sf = fieldnames(new_parameters.(f{i})); % sub-fields
        for ii = 1:length(sf)
            if isstruct(new_parameters.(f{i}).(sf{ii})) % nested level 2
                ssf = fieldnames(new_parameters.(f{i}).(sf{ii}));
                for iii = 1:length(ssf)
                    % Replace sub-sub-fields
                    parameters.(f{i}).(sf{ii}).(ssf{iii}) = new_parameters.(f{i}).(sf{ii}).(ssf{iii});
                end
            else
                % Replace sub-fields
                parameters.(f{i}).(sf{ii}) = new_parameters.(f{i}).(sf{ii});
            end
        end
    else
        % Replace fields
        parameters.(f{i}) = new_parameters.(f{i});
    end
end


end

