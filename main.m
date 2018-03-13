%% parameters

filename = './images/custom-4.jpg';
name = 'result-4';

k = 1.2;
num_level = 14;
sigma_initial = 2;

method = Method.DOG; % INCREASE_FILTER_SIZE, DOWNSAMPLE_IMAGE, DOG

ns_radius = 1;
overlap_t = 0;

if (method == Method.DOWNSAMPLE_IMAGE)
    t = 0.00013;
elseif (method == Method.INCREASE_FILTER_SIZE)
    t = 0.002;
elseif (method == Method.DOG)
    t = 0.00025;
end

ENABLE_HARRIS_EDGE_REMOVE = false;
harris_t = 0.5;

ENABLE_AFFINE = false;
ENABLE_AFFINE_REMOVE = false;
affine_t = 6;

%% Load image

im = im2double(rgb2gray(imread(filename)));
[h, w] = size(im);

%% Build a Laplacian scale space

scale_space = cell(num_level, 1);

sigma = sigma_initial;
sigmas = zeros(1, num_level);

filters = cell(num_level, 1);

tic

if (method == Method.DOG)
    
    filter_size = round(3 * sigma_initial) * 2 + 1;
    filters{1} = fspecial('gaussian', filter_size, sigma_initial);
    
    temp = conv2(im, filters{1}, 'same');
    
    for i = 1 : num_level
        sigmas(i) = sigma;

        filters{i} = filters{1};

        im_downsample = imresize(im, (1 / k) ^ i);
        im_conv = conv2(im_downsample, filters{i}, 'same');
        im_resize = imresize(im_conv, [h w], 'bicubic');
        scale_space{i} = (im_resize - temp) .^ 2;
        temp = im_resize;

        sigma = sigma * k;
    end
    
else

    for i = 1 : num_level
        sigmas(i) = sigma;

        if (method == Method.INCREASE_FILTER_SIZE)
            filter_size = round(3 * sigma) * 2 + 1;
            filters{i} = sigma ^ 2 * fspecial('log', filter_size, sigma);
        elseif (method == Method.DOWNSAMPLE_IMAGE)
            filter_size = round(3 * sigma_initial) * 2 + 1;
            filters{i} = fspecial('log', filter_size, sigma_initial);
        end

        if (method == Method.DOWNSAMPLE_IMAGE)
            im_downsample = imresize(im, (1 / k) ^ (i - 1));
            im_conv = conv2(im_downsample, filters{i}, 'same') .^ 2;
            scale_space{i} = imresize(im_conv, [h w]);
        else
            scale_space{i} = conv2(im, filters{i}, 'same') .^ 2;
        end

        sigma = sigma * k;
    end

end

toc

% figure(1);
% for i = 1 : num_level
%     subplot(2, floor(num_level / 2), i); imshow(uint8(255 * mat2gray(scale_space{i})));
% end

%% Perform nonmaximum suppression in scale space.

max_layers = zeros(h, w, num_level);
pixel_loc = [];

ns_size = 2 * ns_radius + 1;

for i = 1 : num_level
    temp = scale_space{i};
    ns_size = 2 * ceil(ns_radius + sigmas(i) * overlap_t) + 1;
    max_layers(:,:,i) = ordfilt2(temp, ns_size ^ 2, ones(ns_size));
end

[max_layers] = ordfilt3D(max_layers, 27);

max_alls = zeros(h, w, num_level);

for i = 1 : num_level
    ms = ceil(sqrt(2) * sigmas(i));
    mask = zeros(h, w);
    mask((ms + 1) : (h - ms), (ms + 1) : (w - ms)) = ones(h - 2*ms, w - 2*ms);
    mask_blur = imgaussfilt(mask, sigmas(i));
    max_alls(:,:,i) = scale_space{i} .* mask;
end

max_all = max(max_alls, [], 3);

% harris

[~, ~, ~, Ix2, Iy2, Ixy] = harris(im, sigma_initial);
edge = (Ix2(:, :) - Iy2(:, :)) .^ 2;

for i = 1 : num_level
    cim = scale_space{i};
    
    ms = ceil(sqrt(2) * sigmas(i));
    mask = zeros(h, w);
    mask((ms + 1) : (h - ms), (ms + 1) : (w - ms)) = ones(h - 2*ms, w - 2*ms);
    
    edge_blur = imgaussfilt(edge, sigmas(i));

    cim = (cim == max_layers(:,:,i)) & (cim > t) & (mask(:,:)) & (cim == max_all);

%     if (i > 1 && i < num_level)
%         cim = (cim == max_layers(:,:,i)) & (cim > t) & (mask(:,:)) ...
%             & (cim > max_layers(:,:,i-1)) & (cim > max_layers(:,:,i+1));
%     elseif (i == 1)
%         cim = (cim == max_layers(:,:,i)) & (cim > t) & (mask(:,:)) ...
%             & (cim > max_layers(:,:,i+1));
%     else
%         cim = (cim == max_layers(:,:,i)) & (cim > t) & (mask(:,:)) ...
%             & (cim > max_layers(:,:,i-1));
%     end
    
    if (ENABLE_HARRIS_EDGE_REMOVE)
        cim = cim & (edge_blur(:, :) < harris_t);
    end
    
    [r, c] = find(cim);
    l = i * ones(size(r, 1), 1);
    pixel_loc = [pixel_loc; [r, c, l]];
end
pixel_loc = pixel_loc(2 : end, : );

%% Display resulting circles at their characteristic scales.

for i=1 : size(pixel_loc, 1)
    pixel_loc(i,3) = sqrt(2) * sigmas(pixel_loc(i, 3));
end

dx = [-1 0 1; -1 0 1; -1 0 1]; % Derivative masks
dy = dx';

Ix = conv2(im, dx, 'same');    % Image derivatives
Iy = conv2(im, dy, 'same');    

Ix2 = Ix.^2;
Iy2 = Iy.^2;
Ixy = Ix.*Iy;

e = zeros(size(pixel_loc, 1), 3);

if (ENABLE_AFFINE)
    for i = 1 : size(pixel_loc, 1)
        mask = createCirclesMask(im, [pixel_loc(i,1), pixel_loc(i,2), pixel_loc(i,3)]);
        
        a = sum(sum(Ix2 .* mask));
        c = sum(sum(Iy2 .* mask));
        b = sum(sum(Ixy .* mask));
%         [a, b, c, ~, ~] = invSqrt(a, b, c);
        M = [a, b; b, c];
        [V, D] = eig(M);
        
        temp = [D(1,1) D(2,2)];
        l1 = max(temp);
        l2 = min(temp);
        if (D(1,1) ~= l1)
            temp = V(:,1);
            V(:,1) = V(:,2);
            V(:,2) = temp;
        end

%         e(i, 1) = l1 / (l1 + l2);
%         e(i, 2) = l2 / (l1 + l2);
        e(i, 1) = sqrt(l2 / l1) * (1 + sqrt(l2 / l1));
        e(i, 2) = 1 * (1 + sqrt(l2 / l1));
        e(i, 3) = acos(V(1,1) / sqrt(sum(V(:,1) .^ 2)));
        
        if (ENABLE_AFFINE_REMOVE && l1 / l2 > affine_t)
            pixel_loc(i,3) = 0;
        end
%         break;
    end
end

e = e(pixel_loc(:,3) ~= 0,:);
pixel_loc = pixel_loc(pixel_loc(:,3) ~= 0,:);

h = figure(1);
if (ENABLE_AFFINE)
    show_all_ellipses(im, pixel_loc(:,2), pixel_loc(:,1), pixel_loc(:,3), e(:,1), e(:,2), e(:,3));
else
    show_all_circles(im, pixel_loc(:,2), pixel_loc(:,1), pixel_loc(:,3));
end
saveas(h, name, 'jpg');