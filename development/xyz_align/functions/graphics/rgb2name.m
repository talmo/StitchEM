function name = rgb2name(rgb, long_name)
%RGB2NAME Returns the name of a fixed RGB color.
% Set long_name to false to return the short name.
% Returns an empty string if the color is not found.

if nargin < 2
    long_name = true;
end

colorspec = fixed_colors;

[~, i] = ismember(rgb, colorspec.rgb_triples, 'rows');

if i == 0
    name = '';
    return
end

if long_name
    name = colorspec.long_names{i};
else
    name = colorspec.short_names{i};
end

end

