function sec = rough_align(sec, varargin)
%ROUGH_ALIGN Does a rough alignment on the section based on registration to its overview.

% Parse inputs
[params, unmatched_params] = parse_input(varargin{:});

if params.verbosity > 0
    fprintf('== Rough aligning tiles for section %d.\n', sec.num)
end
total_time = tic;

% Slice out variables needed in loop
sec_num = sec.num;
tiles = sec.tiles.rough.img;
tile_prescale = sec.tiles.rough.scale;
overview = sec.overview.img;
overview_prescale = sec.overview.scale;
overview_tform = sec.overview.alignment.tform;
verbosity = params.verbosity;

% Estimate alignments
rough_alignments = cell(sec.num_tiles, 1);
tforms = cell(sec.num_tiles, 1);
parfor tile_num = 1:sec.num_tiles
    registration_time = tic;
    try
        [rough_alignments{tile_num}, tforms{tile_num}] = estimate_tile_alignment(tiles{tile_num}, overview, overview_tform, 'tile_pre_scale', tile_prescale, 'overview_prescale', overview_prescale, unmatched_params);
    catch
        if verbosity > 2
            fprintf('Failed to register section %d -> tile %d to its overview. [%.2fs]\n', sec_num, tile_num, toc(registration_time))
        end
        continue
    end
    if verbosity > 2
        fprintf('Estimated rough alignment for section %d -> tile %d. [%.2fs]\n', sec_num, tile_num, toc(registration_time))
    end
end

successful_registrations = find(cellfun(@(x) ~isempty(x), rough_alignments));
if params.verbosity > 1
    registered_str = strjoin(cellfun(@(x) num2str(x), num2cell(successful_registrations), 'UniformOutput', false)', ', ');
    fprintf('Aligned tiles to overview: %s\n', registered_str)
end

% Some tiles might have failed to be registered, in which case just align
% based on their grid position relative to the nearest registered tile
failed_registrations = find(cellfun('isempty', rough_alignments));
if any(failed_registrations)
    rough_alignments = estimate_tile_grid_alignments(rough_alignments);
    
    if params.verbosity > 1
        failed_str = strjoin(cellfun(@(x) num2str(x), num2cell(failed_registrations), 'UniformOutput', false)', ', ');
        fprintf('Aligned tiles to grid: %s\n', failed_str)
    end
end

% Save to section structure (legacy)
sec.rough_tforms = rough_alignments;
sec.grid_aligned = failed_registrations;

% Save to section structure
rough.tforms = rough_alignments;
rough.rel_tforms = rough_alignments;
rough.rel_to = 'initial';
rough.meta.intermediate_tforms = tforms;
rough.meta.tile_scale = tile_prescale;
rough.meta.overview_tform = overview_tform;
rough.meta.overview_scale = overview_prescale;
rough.meta.overview_rel_to_sec = sec.overview.alignment.rel_to_sec;
rough.meta.grid_aligned = failed_registrations;
rough.meta.assumed_overlap = 0.1;
sec.alignments.rough = rough;

if params.verbosity > 0
    fprintf('Registered %d/%d tiles to overview. [%.2fs]\n', length(successful_registrations), sec.num_tiles, toc(total_time))
end

% Show merge
if params.show_registration
    figure
    imshow_section(sec, 'tforms', 'rough')
end
end

function [params, unmatched] = parse_input(varargin)
% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Debugging
p.addParameter('verbosity', 1);

% Visualization
p.addParameter('show_registration', false);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;
end