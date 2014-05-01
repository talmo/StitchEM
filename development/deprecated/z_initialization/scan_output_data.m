function scan_output_data(output_data)
%SCAN_OUTPUT_DATA Looks for bad results in the output data.

for i = 1:length(output_data)
    % Failed to calculate transform at all
    if isempty(output_data{i})
        fprintf('Section %d: Failed to calculate transform.\n', i)
        continue
    end
    
    % Mean distance between registered points is usually never exactly 0
    if output_data{i}{3} == 0
        fprintf('Section %d: Mean distance betwen registered points is 0.\n', i)
    end
    
    % But a large distance is indicative of a slightly subpar registration
    if output_data{i}{3} >= 1.0
        fprintf('Section %d: Mean distance betwen registered points is %f.\n', i, output_data{i}{3})
    end
    
    % Analyze calculated transformation
    tform = output_data{i}{2};
    [theta, tx, ty, scale] = analyze_tform(tform);
    
    % Bad scaling
    if scale < 0.90 || scale > 1.10
        fprintf('Section %d: Scaled by %f.\n', i, scale)
    end
    
    % Weird angle
    if abs(theta) > 30
        fprintf('Section %d: Rotated by %f degrees (CCW).\n', i, theta)
    end
    
    % Too much translation
    if abs(tx) > 500 || abs(ty) > 500
        fprintf('Section %d: Translated by [%f %f].\n', i, tx, ty)
    end
    
    
end

end

