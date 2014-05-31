function plot_z_matches(secA, secB)
%PLOT_Z_MATCHES Plots the matches between a pair of sections.
% Usage:
%   plot_z_matches(secA, secB)

figure
plot_section(secA, 'z', 'r0.1')
plot_section(secB, 'prev_z', 'g0.1')
plot_matches(secB.z_matches)

end

