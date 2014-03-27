first_sec = 100;
num_secs = 3;
keep_rough_tiles = false;

% Initialize structures
matchesA = cell(num_secs, 1);
matchesB = cell(num_secs, 1);
secs = cell(num_secs, 1);

% Find matches
for i = 1:num_secs
    sec_num = first_sec + i - 1;
    fprintf('==== Processing section %d (%d/%d).\n', sec_num, i, num_secs)
    section_time = tic;
    
    % Load section
    sec = load_sec(sec_num);
    
    % Register overview to last section
    if i > 1
        sec.overview_tform = register_overviews(sec, secs{i - 1}, 'show_registration', false);
    end
    
    % Rough tile alignment
    sec = rough_align_tiles(sec, 'show_registration', false);
    
    % Detect features
    sec = detect_section_features(sec);
    
    % Match XY features
    [matchesA{i}, matchesB{i}] = match_section_features(sec, 'show_matches', false);
    
    % Match Z features
    if i > 1 && ~isempty(secs{i - 1}.z_features)
        [z_matchesA, z_matchesB] = match_section_pair(sec, secs{i - 1}, 'show_matches', false);
        matchesA{i} = [matchesA{i}; z_matchesA];
        matchesB{i} = [matchesB{i}; z_matchesB];
    end
    
    % Cache section
    secs{i} = sec;

    % Clear unneeded data structures to save memory
    secs{i}.img.xy_tiles = [];
    secs{i}.img.z_tiles = [];
    if ~keep_rough_tiles
        secs{i}.img.rough_tiles = [];
    end
    secs{i}.xy_features = [];
    clear z_matchesA z_matchesB sec
    if i > 1
        secs{i - 1}.z_features = [];
        secs{i - 1}.img.overview = [];
    end

    fprintf('== Done processing section %d (%d/%d). [%.2fs]\n\n', secs{i}.num, i, num_secs, toc(section_time))
end

% Merge match tables
matchesA = vertcat(matchesA{:});
matchesB = vertcat(matchesB{:});

%% Rigidity curve
% Plot a large range of lambdas
lambda_curve(matchesA, matchesB)

% Narrow down to a local minimum to find the ideal parameter
lambda_curve(matchesA, matchesB, linspace(0.125 - 0.05, 0.125 + 0.05, 50), 'log_plot', false)

%% Solve transforms
secs = align_section_stack(secs, matchesA, matchesB, 'lambda', 0.125);

%% Render
profile on -memory
render_scale = 0.025;
render_path = sprintf('renders/%sx', num2str(render_scale));

render_stack(secs, 'tile_images', 'load', 'render_scale', render_scale, 'path', render_path)

profile off
profile viewer

% Inspect render
%sec1 = imread(fullfile(render_path, sprintf('sec%sx.tif', secs{1}.num)));
%imshow(sec1)