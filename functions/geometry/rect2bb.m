function bb = rect2bb(rect)
%RECT2BB Takes a [xmin ymin width height] vector and returns a bounding box polygon.
% Usage:
%   bb = rect2bb(rect)

P1 = rect(1:2);
P2 = rect(1:2) + [rect(3) 0];
P3 = rect(1:2) + [0 rect(4)];
P4 = rect(1:2) + [rect(3) rect(4)];

bb = minaabb([P1; P2; P3; P4]);

end

