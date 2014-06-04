%% Configuration
%secs = [wafers{1}(end-5:end); wafers{2}(1:5)];
secs = vertcat(wafers{:});
alignment = 'stack_z';
scale = 0.05;
CLAHE = true;

output_folder = fullfile(renderspath, sprintf('S2-W002-W005_merged_z_%sx', num2str(scale)));

%% Stack ref
Rs = cell(length(secs), 1);
for s = 1:length(secs)
    % For convenience
    sec = secs{s};
    sizes = sec.tile_sizes;
    tforms = sec.alignments.(alignment).tforms;
    
    % Refs before alignment
    initial_Rs = cellfun(@imref2d, sec.tile_sizes, 'UniformOutput', false);
    
    % Scale
    initial_Rs = cellfun(@(R) scale_ref(R, scale), initial_Rs, 'UniformOutput', false);
    
    % Estimate spatial references after alignment
    Rs{s} = cellfun(@tform_spatial_ref, initial_Rs, tforms, 'UniformOutput', false);
end

% Flatten and merge spatial refs
Rs = vertcat(Rs{:});
stack_R = merge_spatial_refs(Rs);
disp('Merged stack refs.')

%% Render sections
for s = 1:length(secs)
    % Render
    rendered = render_section(secs{s}, alignment, stack_R, 'scale', scale);
    
    % CLAHE
    if CLAHE
        rendered = adapthisteq(rendered);
    end
    
    % Write to disk
    if s == 1
        folder_path = create_folder(output_folder);
    end
    imwrite(rendered, fullfile(folder_path, [secs{s}.name '.tif']))
end
clear rendered