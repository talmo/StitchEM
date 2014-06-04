% Opens current alignment script
if exist('status', 'var') && isfield(status, 'pipeline_script')
    open(status.pipeline_script)
else
    error('No alignment appears to be in process. Check ''status.pipeline_script''.')
end