try
    switch status.step
        case 'xy'
            troubleshoot_xy
        case 'z'
            troubleshoot_z
    end
catch troubleshooter_error
    disp('Something went wrong with the troubleshooter.')
end
disp('<strong>Original error</strong>:')
rethrow(alignment_error)