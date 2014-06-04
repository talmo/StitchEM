function plot_section_pair(secA, alignmentA, secB, alignmentB)
%PLOT_SECTION_PAIR Plots a pair of sections and their alignments.
% Usage:
%   plot_section_pair(secA, secB)
%   plot_section_pair(secA, secB, alignmentB)
%   plot_section_pair(secA, alignmentA, secB, alignmentB)

switch nargin
    case 2
        secB = alignmentA;
        alignmentA = 'z';
        alignmentsB = fieldnames(secB.alignments);
        alignmentB = alignmentsB{end};
    case 3
        alignmentB = secB;
        secB = alignmentA;
        alignmentA = 'z';
end

figure
plot_section(secA, alignmentA, 'r0.1')
plot_section(secB, alignmentB, 'g0.1')


end

