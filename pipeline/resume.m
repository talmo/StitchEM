% Resume alignment
if exist('status', 'var') && isfield(status, 'pipeline_script')
    eval(status.pipeline_script)
else
    error('No alignment appears to be in process. Check ''status.pipeline_script''.')
end