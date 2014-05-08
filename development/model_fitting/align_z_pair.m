function [alignmentA, alignmentB] = align_z_pair(secA, secB, z_matches, varargin)
%ALIGN_Z_PAIR Aligns a pair of sections.
% Usage:
%   [alignmentA, alignmentB] = align_z_pair(secA, secB, z_matches)

% Process parameters
[params, ~] = parse_input(varargin{:});
tic;

if params.verbosity > 0; fprintf('== Aligning section %d to section %d\n', secA.num, secB.num); end

% Merge section matches into a single table
matches = merge_match_sets(z_matches);

% Solve for alignment relative to xy alignment
[all_rel_tforms, avg_prior_error, avg_post_error] = sp_lsq(matches, params.fixed_tile);

% Put each section's transform in its own column
all_rel_tforms = reshape(all_rel_tforms, max(secA.num_tiles, secB.num_tiles), []);


% Process Section A
rel_tforms = all_rel_tforms(:, 1);

% Compose with XY transforms
tforms = cellfun(@(xy, rel) compose_tforms(xy, rel), secA.alignments.xy.tforms, rel_tforms, 'UniformOutput', false);

% Save to data structures
alignmentA.tforms = tforms;
alignmentA.rel_tforms = rel_tforms;
alignmentA.rel_to = 'xy';
alignmentA.meta.fixed_tile = params.fixed_tile;
alignmentA.meta.avg_prior_error = avg_prior_error;
alignmentA.meta.avg_post_error = avg_post_error;


% Process Section B
rel_tforms = all_rel_tforms(:, 2);

% Compose with XY transforms
tforms = cellfun(@(xy, rel) compose_tforms(xy, rel), secB.alignments.xy.tforms, rel_tforms, 'UniformOutput', false);

% Save to data structures
alignmentB.tforms = tforms;
alignmentB.rel_tforms = rel_tforms;
alignmentB.rel_to = 'xy';
alignmentB.meta.fixed_tile = params.fixed_tile;
alignmentB.meta.avg_prior_error = avg_prior_error;
alignmentB.meta.avg_post_error = avg_post_error;
alignmentB.meta.method = mfilename;


if params.verbosity > 0; fprintf('Error: %f -> %fpx / match (%d matches) [%.2fs]\n', avg_prior_error, avg_post_error, z_matches.num_matches, toc); end

end

function [params, unmatched] = parse_input(varargin)

% Create inputParser instance
p = inputParser;
p.KeepUnmatched = true;

% Alignment
p.addParameter('fixed_tile', 1);

% Verbosity
p.addParameter('verbosity', 1);

% Validate and parse input
p.parse(varargin{:});
params = p.Results;
unmatched = p.Unmatched;

end

