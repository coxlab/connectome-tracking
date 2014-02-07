home_dir = '/n/home08/vtan';

dataset = 'isbi_merged';
base_fname = 'train-';
sz = 1024;
filename = [home_dir '/segmentations/isbi13_trn70_tst30b_contrast.tif'];

% dataset = 'ecs';
% base_fname = 'ecs350_';
% sz = 350;
% filename = [home_dir '/segmentations/ecs350_edges_trn14-20_tst0-9_new.tif'];

% read in segmentation from multipage tiff to 3D array 'Segmentations'
tiffInfo = imfinfo(filename);
numFrames = numel(tiffInfo);
Segmentations = zeros(sz, sz, numFrames);
for i = 1:numFrames
    Segmentations(:,:,i) = double(imread(filename,'Index',i,'Info',tiffInfo));
end

% read in labels from multipage tiff to 3D array 'Labels'
Labels = zeros(sz, sz, numFrames);
for i = 1:numFrames
    filename = sprintf([home_dir '/' dataset '/pngs/' base_fname 'labels.tif-%02d.png'], i-1+70);
    Labels(:,:,i) = double(imread(filename));
end


%% watershed transform

for i = 1:30
    im1 = Segmentations(:,:,i);
    im2 = imcomplement(im1);

    im3 = imhmin(im2, 0.325);
    im4 = watershed(im3);
   
    figure; imshow(im4,[]);
    figure; imshow(im6 > 0,[]);

    CC = bwconncomp(im4);
    L = labelmatrix(CC);

    figure; imshow(L, []); colormap('colorcube');
    figure; imshow(imfuse(Labels(:,:,i), label2rgb(L, 'colorcube'), 'blend'));

end


%% hysteresis thresholding

im2 = imcomplement(im1);
im2b = imclose(im2, strel('disk',1));
im2b = imclose(im2b, strel('line',5, 45));
im2b = imclose(im2b, strel('line',5, 0));
im2b = imclose(im2b, strel('line',5, 90));
im2b = imclose(im2b, strel('line',5, 135));

im2b = imadjust(im2b);
im1 = imcomplement(im2b);

thresh_low = 0.9;
thresh_high = 0.95;

im2 = im1 > thresh_low; 
[x_high, y_high] = find(im1 > thresh_high);
im3 = bwselect(im2, y_high, x_high, 4);

CC = bwconncomp(im3);
L = labelmatrix(CC);

% for j = 1:length(CC.PixelIdxList)
% % for j = 1:2
%     [x,y] = ind2sub(size(L), CC.PixelIdxList{j});
%     K = convhull(x,y);
%     L(sub2ind(size(L), x(K), y(K))) = 50;
% end

figure; imshow(im1);
figure; imshow(im2);
% figure; imshow(L, []); colormap('colorcube');
% figure; imshow(imfuse(Labels(:,:,i), label2rgb(L, 'colorcube'), 'blend'));

