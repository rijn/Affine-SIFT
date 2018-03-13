function show_all_ellipses(I, cx, cy, rad, a, b, t, color, ln_wid)
%% I: image on top of which you want to display the circles
%% cx, cy: column vectors with x and y coordinates of circle centers
%% rad: column vector with radii of circles. 
%% The sizes of cx, cy, and rad must all be the same
%% color: optional parameter specifying the color of the circles
%%        to be displayed (red by default)
%% ln_wid: line width of circles (optional, 1.5 by default

if nargin < 8
    color = 'r';
end

if nargin < 9
   ln_wid = 1.5;
end

imshow(I); hold on;

theta = 0:0.1:(2*pi+0.1);
cx1 = cx(:,ones(size(theta)));
cy1 = cy(:,ones(size(theta)));
rad1 = rad(:,ones(size(theta)));
a1 = a(:,ones(size(theta)));
b1 = b(:,ones(size(theta)));
t1 = t(:,ones(size(theta)));
theta = theta(ones(size(cx1,1),1),:);
U = cos(theta).*rad1.*a1;
V = sin(theta).*rad1.*b1;
X = cx1 + U.*cos(t1) - V.*sin(t1);
Y = cy1 + U.*sin(t1) + V.*cos(t1);
line(X', Y', 'Color', color, 'LineWidth', ln_wid);

title(sprintf('%d circles', size(cx,1)));
