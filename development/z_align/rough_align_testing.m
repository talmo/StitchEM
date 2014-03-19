first_sec_num = 100;
num_secs = 10;
tile_resize_scale = 0.125;

secs = cell(num_secs, 1);
data = table([], [], [], [], [], [], 'VariableNames', {'sec_num', 'num_failed', 'num_success', 'overview_scale', 'tile_scale', 'params'});
%% Load section images
disp('==== Loading section images.')
for i = 1:num_secs
    secs{i} = sec_struct(first_sec_num + i - 1, tile_resize_scale, false);
end

%% Register section overviews
disp('==== Registering section overview images.')
for i = 1:num_secs - 1
    if all(all(secs{i+1}.overview_tform.T == eye(3)))
        % Register section i + 1 to i
        try
            secs{i+1}.overview_tform = register_overviews(secs{i}.img.overview, secs{i}.overview_tform, secs{i+1}.img.overview);
            fprintf('Registered the overviews for section %d to %d.\n', secs{i+1}.num, secs{i}.num)
        catch
            fprintf('Failed to register overviews for section %d to %d. Sections will not be aligned to each other.\n', secs{i+1}.num, secs{i}.num)
        end
    else
        % Section i + 1 already has a registration transform to section i
        disp('Sections overviews are already registered.')
    end
end

%% Calculate rough tile alignments

for rough_align_overview_scale = 0.7:0.02:1.0
    scale_register_time = tic;
    % Rough alignment scaling
    %rough_align_overview_scale = 1.0; % default = 0.5
    rough_align_tile_scale = rough_align_overview_scale * 0.07; % default = 0.05
    % tiles in the overview are ~0.07x scale of tile

    % Rough alignment SURF params
    register_params.SURF_MetricThreshold = 1000; % MATLAB default = 1000
    register_params.SURF_NumOctaves = 3; % MATLAB default = 3
    register_params.SURF_NumScaleLevels = 4; % MATLAB default = 4
    register_params.SURFSize = 64; % MATLAB default = 64

    % Rough alignment Matching params
    register_params.NNR_MatchThreshold = 1.0; % MATLAB default = 1.0
    register_params.NNR_MaxRatio = 0.6; % MATLAB default = 0.6

    % Rough alignment Transform estimation params
    register_params.MSAC_transformType = 'similarity'; % MATLAB default = 'similarity'
    register_params.MSAC_MaxNumTrials = 500; % MATLAB default = 1000
    register_params.MSAC_Confidence = 99; % MATLAB default = 99
    register_params.MSAC_MaxDistance = 1.5; % MATLAB default = 1.5

    disp('==== Estimating rough tile alignments.')
    for i = 1:num_secs
        [secs{i}.rough_alignments, secs{i}.grid_aligned] = rough_align_tiles(secs{i}, ...
            'overview_scale', rough_align_overview_scale, 'tile_scale', rough_align_tile_scale, register_params);

        % Data collection
        sec_num = secs{i}.num;
        num_failed = length(secs{i}.grid_aligned);
        num_success = secs{i}.num_tiles - length(secs{i}.grid_aligned);
        overview_scale = rough_align_overview_scale;
        tile_scale = rough_align_tile_scale;
        params = register_params;
        data = [data; table(sec_num, num_failed, num_success, overview_scale, tile_scale, params)];
    end
    fprintf('Done estimating rough tile alignments at %fx. [%.2fs]\n', rough_align_overview_scale, toc(scale_register_time))
end

%% Data visualization

scales = data.overview_scale;
success_rates = data.num_success ./ (data.num_success + data.num_failed);
mean_success_rates = arrayfun(@(x) mean(success_rates(data.overview_scale == x)), unique(scales));

figure
plot(unique(scales), mean_success_rates, 'x')
xlabel('overview scale'), ylabel('mean success rate (per section)')

% 2d
% figure
% plot(scales, success_rates, 'x')
% xlabel('overview scale'), ylabel('success rate')
% 
% 3d
% figure
% hist3([scales, success_rates], [16, 16])
% xlabel('overview scale'), ylabel('success rate'), zlabel('frequency')
% set(get(gca,'child'),'FaceColor','interp','CDataMode','auto')