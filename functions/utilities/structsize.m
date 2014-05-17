function sizes = structsize(S)
%STRUCTSIZE Displays and optionally returns the size in MB of the fields of the specified structure.

for f = fieldnames(S)'
    field = S.(f{1});
    field_info = whos('field');
    field_size = field_info.bytes / 1024 / 1024;
    if nargout < 1
        fprintf('<strong>%s</strong>: %f MB [%s]\n', f{1}, field_size, field_info.class);
    else
        sizes.(f{1}) = field_size;
    end
end

end

