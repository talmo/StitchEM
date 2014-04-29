function [I1, I2] = intersect_line_segs(P1, P2, U1, U2)
%INTERSECT_LINE_SEGS Computes the intersection between the line segments P and U.
%
% Args:
%   P1, P2 are the endpoint coordinates of the line segment P.
%   U1, U2 are the endpoint coordinates of the line segment U.
%   You may also call this function with two arguments of the form:
%       [P1; P2], [U1; U2].
%
% Returns:
%   I1 contains a point of intersection between P and U if they intersect,
%       otherwise it is empty.
%   I2 contains the second endpoint of the line segment [I1, I2] if P and U
%       overlap, otherwise it is empty.
%
% If there are less than 2 outputs, [I1; I2] is returned instead.
%
% Reference:
%   http://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect/565282#565282
%   http://geomalgorithms.com/a05-_intersect-1.html

% Line segment equations:
%   P1 + r * (P2 - P1), r = [0, 1]
%   U1 + s * (U2 - U1), s = [0, 1]

if nargin == 2
    % Convert from block format to single points
    P_ = P1; U_ = P2;
    P1 = P_(1, :); P2 = P_(2, :);
    U1 = U_(1, :); U2 = U_(2, :);
end

% In terms of the direction vectors Q and V:
P = P1; Q = P2 - P1; % => P + r * Q, r = [0, 1]
U = U1; V = U2 - U1; % => U + s * V, s = [0, 1]

% We must first check if the lines are parallel, in which case they will
% only intersect if they are coincident.

% We can do this by verifying if their direction vectors are collinear:
QxV = cross2(Q, V); % same as perpdot(Q, V)
if QxV == 0
    
    % The lines are parallel, now we can check if they are collinear:
    if cross2(U - P, V) == 0
        % The lines are collinear, now we check if they are coincident:
        
        % First, solve for the endpoints of U with the equation for P:
        i = find(Q ~= 0); % avoid division by zero error
        r1 = (U1(i) - P(i)) / Q(i);
        r2 = (U2(i) - P(i)) / Q(i);
        
        % Express as intervals:
        r_P = [0 1];
        r_U = sort([r1, r2]);
        
        % Find the intersection of the two intervals
        r_UinP = [max(r_P(1), r_U(1)), min(r_P(2), r_U(2))];
        
        if r_UinP(1) > r_UinP(2)
            % P and U are disjoint
            I1 = [];
            I2 = [];
        elseif r_UinP(1) == r_UinP(2)
            % P and U intersect at one point
            I1 = P + r_UinP(1) * Q;
            I2 = [];
        else
            % P and U overlap (coincide)
            I1 = P + r_UinP(1) * Q;
            I2 = P + r_UinP(2) * Q;
        end
    else
        % The lines are just parallel
        I1 = [];
        I2 = [];
    end
else
    % The lines are non-parallel, now we check if they intersect:
   
    % Find the parameters where the lines intersect:
    r_I = cross2((U - P), V) / QxV;
    s_I = cross2((U - P), Q) / QxV;
    
    if 0 <= r_I && r_I <= 1 && 0 <= s_I && s_I <= 1
        % The line segments intersect
        I1 = P + r_I * Q;
        I2 = [];
    else
        % The line segments do not intersect
        I1 = [];
        I2 = [];
    end
end

if nargout < 2
    I1 = [I1; I2];
end
end

