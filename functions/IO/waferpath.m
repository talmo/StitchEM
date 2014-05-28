function current_path = waferpath(new_path, force)
%WAFERPATH Gets or sets the current wafer path.
% Usage:
%   current_path = waferpath()
%   waferpath(new_path)
%   waferpath(new_path, force)
%
% Args:
%   new_path: path to a wafer folder
%   force: set this to true to force using specified path even if it isn't
%       detected as a wafer folder.
%
% See also: get_path_info

persistent wafer_path;

if nargin < 1
    new_path = [];
end
if nargin < 2
    force = false;
end

% Set new path
if ~isempty(new_path)
    info = get_path_info(new_path);
    
    if info.exists && (strcmp(info.type, 'wafer') || force)
        new_path = GetFullPath(new_path);
        wafer_path = new_path;
        disp('Set wafer path.')
    else
        error('Specified path does not exist or contain a wafer folder.')
    end
end

% Error if empty
if isempty(wafer_path)
    error('Wafer path not currently set. Call this function with the path to the a wafer folder to set it.')
end

% Output
if nargout < 1
    info = get_path_info(wafer_path);
    fprintf('<strong>Wafer</strong>: %s\n', info.wafer)
    fprintf('<strong>Path</strong>: %s\n', info.path)
    fprintf('<strong>Sections</strong>: %d-%d (n = %d)\n', min(info.sec_nums), max(info.sec_nums), info.num_secs)
    if ~isempty(info.missing_secs)
        fprintf('<strong>Missing sections</strong>: %s (n = %d)\n', vec2str(info.missing_secs), length(info.missing_secs))
    end
    return
else
   current_path = wafer_path; 
end
end

