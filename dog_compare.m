%% parameters

filename = './images/butterfly.jpg';

k = 1.2;
num_level = 12;
sigma_initial = 2;

method = Method.DOWNSAMPLE_IMAGE; % INCREASE_FILTER_SIZE, DOWNSAMPLE_IMAGE, DOG

%% Load image

im = im2double(rgb2gray(imread(filename)));
[h, w] = size(im);

%% Build a Laplacian scale space

scale_space = cell(num_level, 1);
scale_space_DoG = cell(num_level, 1);

sigma = sigma_initial;
sigmas = zeros(1, num_level);

filters = cell(num_level, 1);

tic

filter_size = round(3 * sigma_initial) * 2 + 1;
filters{1} = fspecial('gaussian', filter_size, sigma_initial);

temp = conv2(im, filters{1}, 'same');

for i = 1 : num_level
    filters{i} = filters{1};

    im_downsample = imresize(im, (1 / k) ^ i);
    im_conv = conv2(im_downsample, filters{i}, 'same');
    im_resize = imresize(im_conv, [h w], 'bicubic');
    scale_space_DoG{i} = (im_resize - temp) .^ 2;
    temp = im_resize;
end

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

for i = 1 : num_level
    scale_space{i} = (scale_space{i} - scale_space_DoG{i}) .^ 2;
end

figure(1);
for i = 1 : num_level
    subplot(3, ceil(num_level / 3), i); imagesc(scale_space{i}); axis off;
    if (i == num_level)
        colorbar;
    end
end

toc
