function mask = createCirclesMask(varargin)
%xDim,yDim,centers,radii)
% Create a binary mask from circle centers and radii
%
% SYNTAX:
% mask = createCirclesMask([xDim,yDim],centers,radii);
% OR
% mask = createCirclesMask(I,centers,radii);
%
% INPUTS: 
% [XDIM, YDIM]   A 1x2 vector indicating the size of the desired
%                mask, as returned by [xDim,yDim,~] = size(img);
%  
% I              As an alternate to specifying the size of the mask 
%                (as above), you may specify an input image, I,  from which
%                size metrics are to be determined.
% 
% CENTERS        An m x 2 vector of [x, y] coordinates of circle centers
%
% RADII          An m x 1 vector of circle radii
%
% OUTPUTS:
% MASK           A logical mask of size [xDim,yDim], true where the circles
%                are indicated, false elsewhere.
%
%%% EXAMPLE 1:
%   img = imread('coins.png');
%   [centers,radii] = imfindcircles(img,[20 30],...
%      'Sensitivity',0.8500,...
%      'EdgeThreshold',0.30,...
%      'Method','PhaseCode',...
%      'ObjectPolarity','Bright');
%   figure
%   subplot(1,2,1);
%   imshow(img)
%   mask = createCirclesMask(img,centers,radii);
%   subplot(1,2,2);
%   imshow(mask)
%
%%% EXAMPLE 2:
%   % Note: Mask creation is the same as in Example 1, but the image is
%   % passed in, rather than the size of the image.
%
%   img = imread('coins.png');
%   [centers,radii] = imfindcircles(img,[20 30],...
%      'Sensitivity',0.8500,...
%      'EdgeThreshold',0.30,...
%      'Method','PhaseCode',...
%      'ObjectPolarity','Bright');
%   mask = createCirclesMask(size(img),centers,radii);
%
% See Also: imfindcircles, viscircles, CircleFinder
%
% Brett Shoelson, PhD
% 9/22/2014
% Comments, suggestions welcome: brett.shoelson@mathworks.com

% Copyright 2014 The MathWorks, Inc.

narginchk(2,2)
if numel(varargin{1}) == 2
	% SIZE specified
	xDim = varargin{1}(1);
	yDim = varargin{1}(2);
else
	% IMAGE specified
	[xDim,yDim] = size(varargin{1});
end
k = varargin{2};
[xx,yy] = meshgrid(1:yDim,1:xDim);
mask = false(xDim,yDim);
mask = mask | hypot(xx - k(2), yy - k(1)) <= k(3);