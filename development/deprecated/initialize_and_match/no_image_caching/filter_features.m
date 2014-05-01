function filtered_features = filter_features(features, variable, criteria, return_all_cols)
%FILTER_FEATURES Returns rows in a features table matching the specified criteria.

%% Parameters
% Defaults
if nargin < 4
    return_all_cols = true;
end

%% Filter table

switch variable
    case 'tile'
        rows = features.tile == criteria;
    case {'local', 'global', 'local_points', 'global_points'}
        % Validate the input
        if numel(criteria) ~= 4
            error('Criteria for finding features in a region must be a 4 element array of the format: [x y width height]')
        end
        
        % Fix the variable name in case the shorthand was used
        if isempty(strfind(variable, 'points'))
            variable = strcat(variable, '_points');
        end
        
        % criteria = [x y width height]
        x = criteria(1);
        y = criteria(2);
        width = criteria(3);
        height = criteria(4);
        
        % Match points within this region
        in_region = @(pt) pt(1) >= x & pt(1) <= x + width & pt(2) >= y & pt(2) <= y + height;
        
        % Pull out the array of points we're searching through from the table
        points = features.(variable);
        
        % Pre-allocate logical indexing array
        rows = false(size(features, 1), 1);
        
        % Loop through rows and check if point is within region
        for i = 1:size(features, 1)
            rows(i) = in_region(points(i, :));
        end
        
        % Alternative way of searching -- but slower
        %rows = cellfun(in_region, num2cell(points, 2));
end

% Return rows matching the criteria
if return_all_cols
    filtered_features = features(rows, :);
else
    filtered_features = features.(variable)(rows, :);
end

end

