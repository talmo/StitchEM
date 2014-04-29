function stitch_log(message, data_path)
%STITCH_LOG Appends a timestamped message to the log file in the stitch data folder.

% Check if /StitchData exists
if ~exist(fileparts(data_path), 'dir')
    mkdir(fileparts(data_path))
end

% Append message with timestamp
fileID = fopen(fullfile(data_path, 'stitch.log'), 'a');
fprintf(fileID, '[%s] %s\n', datestr(now), message);
fclose(fileID);

end
