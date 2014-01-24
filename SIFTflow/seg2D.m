home_dir = '/n/home08/vtan';

% dataset = 'isbi_merged';
% base_fname = 'train-';
% sz = 1024;
% filename = [home_dir '/segmentations/isbi13_trn70_tst30b_contrast.tif'];

dataset = 'ecs';
base_fname = 'ecs350_';
sz = 350;
filename = [home_dir '/segmentations/ecs350_filled_trn14-20_tst0-9_new.tif'];

% read in segmentation from multipage tiff to 3D array 'Segmentations'
tiffInfo = imfinfo(filename);
numFrames = numel(tiffInfo);
Segmentations = zeros(sz, sz, numFrames);
for i = 1:numFrames
    Segmentations(:,:,i) = double(imread(filename,'Index',i,'Info',tiffInfo));
end


% read in labels from multipage tiff to 3D array 'Labels'
% Labels = zeros(sz, sz, numFrames);
% for i = 1:numFrames
%     filename = sprintf([home_dir '/' dataset '/pngs/' base_fname 'labels.tif-%02d.png'], i-1+70);
%     Labels(:,:,i) = double(imread(filename));
% end

im1 = Segmentations(:,:,1);


%% watershed transform
% 
% for i = 1:1
%     im2 = imcomplement(im1);
%     % im2b = imclose(im2, strel('disk',1));
%     % 
%     % for i = 1:10
%     %     im2b = imclose(im2b, strel('line',3, 45));
%     %     im2b = imclose(im2b, strel('line',3, 0));
%     %     im2b = imclose(im2b, strel('line',3, 90));
%     %     im2b = imclose(im2b, strel('line',3, 135));
%     % end
% 
%     % im2b = imadjust(im2b);
% 
%     im3 = imhmin(im2, 0.355);
%     % im3 = imhmin(im2b,0.025);
%     im4 = watershed(im3);
%     
%     im5 = imcomplement(im4);
%     im5b = imclose(im5, strel('disk',6));
%     im5b = imclose(im5b, strel('line',10, 45));
%     im5b = imclose(im5b, strel('line',10, 0));
%     im5b = imclose(im5b, strel('line',10, 90));
%     im5b = imclose(im5b, strel('line',10, 135));
%     im5b = imdilate(im5b, strel('disk',2));
% 
%     im5b = imadjust(im5b);
%     im6 = imcomplement(im5b);
%     
% %     figure; imshow(im4,[]);
%     figure; imshow(im6 > 0,[]);
%     figure; imshow(Labels(:,:,i), []);
% 
% %     CC = bwconncomp(im4);
% %     L = labelmatrix(CC);
% % 
% %     % figure; imshow(im2,[]);
% %     figure; imshow(im4, []);
% %     figure; imshow(L, []); colormap('colorcube');
%     % figure; imshow(imfuse(Labels(:,:,i), label2rgb(L, 'colorcube'), 'blend'));
%     % figure; imshow(im4 > 0);
%     
% %     imwrite(im4 == 0, [home_dir '/' dataset '/isbi13_test_seg_' sprintf('%02d', i-1+70) '.png'], 'PNG');
% %     imwrite(im6 > 0, [home_dir '/' dataset '/isbi13_test_seg_70-99.tif'], 'writemode', 'append', 'compression', 'none');
% end


%% hysteresis thresholding

im2 = imcomplement(im1);
im2b = imclose(im2, strel('disk',1));
im2b = imclose(im2b, strel('line',5, 45));
im2b = imclose(im2b, strel('line',5, 0));
im2b = imclose(im2b, strel('line',5, 90));
im2b = imclose(im2b, strel('line',5, 135));

im2b = imadjust(im2b);
im1 = imcomplement(im2b);

thresh_low = 0.7;
thresh_high = 0.95;

im2 = im1 > thresh_low; 
[x_high, y_high] = find(im1 > thresh_high);
im3 = bwselect(im2, y_high, x_high, 4);
% im4 = im3;
% for i = 1:10
%     im4 = imclose(im4, strel('disk',6));
%     im5 = imopen(im4, strel('disk', 6));
%     im4 = im5;
% end

CC = bwconncomp(im3);
L = labelmatrix(CC);

% for j = 1:length(CC.PixelIdxList)
% % for j = 1:2
%     [x,y] = ind2sub(size(L), CC.PixelIdxList{j});
%     K = convhull(x,y);
%     L(sub2ind(size(L), x(K), y(K))) = 50;
% end

figure; imshow(im1);
figure; imshow(im3);
% figure; imshow(im4);
% figure; imshow(im5);
figure; imshow(L, []); colormap('colorcube');

% figure; imshow(imfuse(Labels(:,:,i), label2rgb(L, 'colorcube'), 'blend'));


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
    