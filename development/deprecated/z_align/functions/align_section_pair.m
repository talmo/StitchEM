function [secA, secB, mean_error, varargout] = align_section_pair(secA, secB, matchesAB, matchesBA, varargin)
%ALIGN_SECTION_PAIR Calculates transforms to align a pair of sections.

% Process input
[params, unmatched_params] = parse_inputs(varargin{:});

% Calculate transforms
[tforms, mean_error] = tikhonov(matchesAB, matchesBA, unmatched_params);

% Apply the calculated transforms to the rough tforms
for t = 1:size(tforms, 2)
    if ~isempty(tforms{1, t})
        secA.fine_alignments{t} = affine2d(secA.rough_alignments{t}.T * tforms{1, t}.T);
    else
        secA.fine_alignments{t} = secA.rough_alignments{t};
    end
    if ~isempty(tforms{2, t})
        secB.fine_alignments{t} = affine2d(secB.rough_alignments{t}.T * tforms{2, t}.T);
    else
        secB.fine_alignments{t} = secB.rough_alignments{t};
    end
end

% Build a summary table of the transforms
if params.show_summary
    scale = []; rotation = []; translation = [];
    for t = 1:length(secA.fine_alignments)
        [s, r, tr] = estimate_tform_params(secA.fine_alignments{t}.T);
        scale = [scale; s]; rotation = [rotation; r]; translation = [translation; tr];
    end
    tile_num = (1:length(scale))';
    tform_params = table(tile_num, scale, rotation, translation);
    disp(tform_params)
    
    scale = []; rotation = []; translation = [];
    for t = 1:length(secB.fine_alignments)
        [s, r, tr] = estimate_tform_params(secB.fine_alignments{t}.T);
        scale = [scale; s]; rotation = [rotation; r]; translation = [translation; tr];
    end
    tile_num = (1:length(scale))';
    tform_params = table(tile_num, scale, rotation, translation);
    disp(tform_params)
end

% Visualization
if params.render_merge || params.show_merge
    [mergeA, mergeA_R] = imshow_section(secA, secA.fine_alignments, 'display_scale', params.display_scale, 'suppress_display', true);
    [mergeB, mergeB_R] = imshow_section(secB, secB.fine_alignments, 'display_scale', params.display_scale, 'suppress_display', true);
    [merge, merge_R] = imfuse(mergeA, mergeA_R, mergeB, mergeB_R);
    
    if params.show_merge
        figure
        imshow(merge, merge_R), hold on
        
        if params.show_matches
            % Transform matches
            registered_pts_A = zeros(size(matchesAB, 1), 2); registered_pts_B = zeros(size(matchesAB, 1), 2);
            for t = 1:size(tforms, 2)
                tile_matchesAB = matchesAB.id(matchesAB.tile == t);
                local_pointsAB = secA.features.local_points(tile_matchesAB, :);
                registered_pts_A(matchesAB.tile == t, 1:2) = secA.fine_alignments{t}.transformPointsForward(local_pointsAB);

                tile_matchesBA = matchesBA.id(matchesBA.tile == t);
                local_pointsBA = secB.features.local_points(tile_matchesBA, :);
                registered_pts_B(matchesBA.tile == t, 1:2) = secB.fine_alignments{t}.transformPointsForward(local_pointsBA);
            end

            plot_matches(registered_pts_A, registered_pts_B, params.display_scale)
        end
        
        title(sprintf('Sections %d and %d registered (mean error = %f px)', secA.num, secB.num, mean_error))
        integer_axes(1/params.display_scale)
        hold off
        
    end
    
    varargout = {merge, merge_R, mergeA, mergeA_R, mergeB, mergeB_R};
    
    if params.show_matches
        varargout = [varargout, {registered_pts_A, registered_pts_B}];
    end
end

end

function [params, unmatched] = parse_inputs(varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Debugging
p.addParameter('show_summary', false);

% Visualization
p.addParameter('show_merge', false);
p.addParameter('show_matches', false);
p.addParameter('render_merge', false);
p.addParameter('display_scale', 0.025);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;

end