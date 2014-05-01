function register_stack(run_name, params)
section_numbers = [1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;20;21;22;23;24;25;26;27;28;29;30;31;32;33;34;35;36;37;38;39;40;41;42;43;44;45;46;47;48;49;50;51;52;53;54;55;56;57;58;59;60;61;62;63;64;65;66;67;68;69;70;71;72;73;74;75;76;77;78;79;80;81;82;83;84;85;86;87;88;89;90;91;92;93;94;95;96;97;98;99;100;101;102;103;104;105;106;107;108;109;110;111;112;113;114;115;116;117;118;119;120;121;122;123;124;125;126;127;128;129;130;131;132;133;134;135;136;137;138;139;140;141;142;143;144;145;146;147;148;149];
%section_numbers = [1;2];
merges = cell(1, length(section_numbers));
output_data = cell(1, length(section_numbers));

%% Loop through sections
for i = section_numbers(1:end-1)'
    fprintf('Section %d <-> %d\n', i, i + 1), tic
    try
        [merge, ~, ~, tform, mean_registered_distances] = feature_based_registration(i, i + 1, params);
        
        % Calculate detected angle and translation
        [theta, tx, ty] = analyze_tform(tform);
        fprintf('Transform Angle: %f, Translation: [%f, %f]\n', theta, tx, ty)
        
        % Save
        merges{i} = merge;
        output_data{i} = {[i, i + 1], tform, mean_registered_distances};
    catch
        disp('Failed to register sections.')
    end
    fprintf('Done in %.2fs.\n\n', toc)
end


%% Save merge images and data
output_path = sprintf('/data/home/talmo/EMdata/W002/z_initialization_merges/merges_24-02-2014/%s/', run_name);
mkdir(output_path);

% Save output data
save(sprintf('%srun_data.mat', output_path), 'output_data', 'params');


% Save images
for i = 1:length(merges)
    if ~isempty(merges{i})
        imwrite(merges{i}, sprintf('%s%d.tif', output_path, i));
    else
        fprintf('No merge for %d.\n', i)
    end
end
end