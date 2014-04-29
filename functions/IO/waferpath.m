function cur_path = waferpath(path)
%WAFERPATH Gets or sets the current wafer path.

persistent wafer_path;

if nargin > 0
    if exist(path, 'dir')
        wafer_path = path;
        if nargout < 1
            return
        end
    else
        error('Specified wafer path does not exist.')
    end
end

if isempty(wafer_path)
    error('Wafer path not currently set. Call this function with the path to the current wafer as the parameter to set it.')
end
if ~exist(wafer_path, 'dir')
    error('Current wafer path does not exist. Call this function with the path to the current wafer as the parameter to set it.\nCurrent path: %s', wafer_path)
end

cur_path = wafer_path;
end

