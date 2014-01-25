home_dir = '/home/vyt/Documents/Research';
dataset = 'ecs';
%base_fname = 'train-input-norm-';
base_fname = 'ecs350_';
sz = 350;

% read in segmentation from multipage tiff to 3D array 'Segmentations'
filename = [home_dir '/segmentations/ecs350_trn20_tst10.tif'];
tiffInfo = imfinfo(filename);
numFrames = numel(tiffInfo);
Segmentations = zeros(sz, sz, numFrames);
for i = 1:numFrames
    Segmentations(:,:,i) = double(imread(filename,'Index',i,'Info',tiffInfo));
end

% read in labels from multipage tiff to 3D array 'Labels'
Labels = zeros(sz, sz, numFrames);
for i = 1:30
    filename = sprintf([home_dir '/' dataset '/pngs/' base_fname 'labels-%02d.png'], i-1);
    Labels(:,:,i) = double(imread(filename));
end


i = 1;
im1 = Segmentations(:,:,i);

%% watershed transform

im2 = imcomplement(im1);
im3 = imhmin(im2,0.2);
im4 = watershed(im3);
CC = bwconncomp(im4);
L = labelmatrix(CC);

figure; imshow(im1,[]);
figure; imshow(L, []); colormap('colorcube');
figure; imshow(imfuse(Labels(:,:,i+20), label2rgb(L, 'colorcube'), 'blend'));


%% hysteresis thresholding
 
thresh_low = 0.6;
thresh_high = 0.85;

im2 = im1 > thresh_low; 
[x_high, y_high] = find(im1 > thresh_high);
im3 = bwselect(im2, y_high, x_high, 4);
CC = bwconncomp(im3);
L = labelmatrix(CC);

% im2 = im1 > threshh;
% CC = bwconncomp(im2);
% L = labelmatrix(CC);

figure; imshow(im1 > thresh_high);
figure; imshow(L, []); colormap('colorcube');

figure; imshow(imfuse(Labels(:,:,i+20), label2rgb(L, 'colorcube'), 'blend'));



%%
%     im1b = Segmentations(:,:,i+1);
%     im2b = imcomplement(im1b);
%     im3b = imhmin(im2b,0.3);
%     im4b = watershed(im3b);
%     [Lb, num] = bwlabel(im4b);
%     % figure;
%     % imshow(im1,[]);
%     figure;
%     imshow(Lb, []);
%     colormap('colorcube');
%     % figure; 
%     % imshow(Labels(:,:,71),[]);
%     % colormap('colorcube');

    %%%%%%%%%%%%%%%
%     filename1 = sprintf([home_dir '/' dataset '/pngs/' base_fname '%02d.png'], 70+k-1);
%     filename2 = sprintf([home_dir '/' dataset '/pngs/' base_fname '%02d.png'], 70+k);
%     im1 = imread(filename1);
%     im2 = imread(filename2);
%     im1=imfilter(im1,fspecial('gaussian',7,1.0),'same','replicate');
%     im2=imfilter(im2,fspecial('gaussian',7,1.0),'same','replicate');
%     im1=im2double(im1);
%     im2=im2double(im2);
%         
%     cellsize=3;
%     gridspacing=1;
% 
%     sift1 = mexDenseSIFT(im1,cellsize,gridspacing);
%     sift2 = mexDenseSIFT(im2,cellsize,gridspacing);
%     
%     SIFTflowpara.alpha=2*255;
%     SIFTflowpara.d=40*255;
%     SIFTflowpara.gamma=0.005*255;
%     SIFTflowpara.nlevels=4;
%     SIFTflowpara.wsize=1;
%     SIFTflowpara.topwsize=10;
%     SIFTflowpara.nTopIterations = 60;
%     SIFTflowpara.nIterations= 30;
%     
%     tic;[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,SIFTflowpara);toc; 
%     warpI2=warpImage(Lb,vx,vy);
%     warpI1=warpImage(L,-vx,-vy);
%     
%     figure;
%     imshow(warpI1, []);
%     colormap('colorcube');
%     figure;
%     imshow(warpI2, []);
%     colormap('colorcube');
%     
%     clear flow;
%     flow(:,:,1)=vx;
%     flow(:,:,2)=vy;
%     flow_field = flowToColor(flow);
%     figure;
%     imshow(flow_field);
%     figure;
%     b = sprintf('~/Documents/Research/isbi_merged/pngs/train-labels.tif-%02d.png', k-1);
%     boundaries = imread(b);
%     overlay = imfuse(boundaries, flow_field, 'blend');
%     imshow(overlay);
    