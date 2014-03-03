function integer_axes(scale)
%INTEGER_AXES Displays the tickmarks in the current figure as integers.

% Doc: http://www.mathworks.com/help/matlab/ref/axes_props.html
% ticklabels can be numeric vectors which are converted to strings
% automatically by calling num2str.

if nargin < 1
    scale = 1.0;
end

xticks = get(gca, 'xtick') * scale;
yticks = get(gca, 'ytick') * scale;

set(gca, 'xticklabel', xticks)
set(gca, 'yticklabel', yticks)

end

