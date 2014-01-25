home_dir = '/home/vyt/Documents/Research';
dataset = 'ecs';
%base_fname = 'train-input-norm-';
base_fname = 'ecs350_';
sz = 350;

% current max label
maxLabel = 0;

% read in segmentation from multipage tiff to 3D array 'Segmentations'
filename = [home_dir '/segmentations/ecs350_trn20_tst10_contrast.tif'];
tiffInfo = imfinfo(filename);
numFrames = numel(tiffInfo);
Segmentations = zeros(sz, sz, numFrames);
for i = 1:numFrames
    Segmentations(:,:,i) = double(imread(filename,'Index',i,'Info',tiffInfo));
end

% read in labels
OldLabels = zeros(sz, sz, numFrames);
Labels = zeros(sz, sz, numFrames);
for i = 1:10
    disp(['frame ' num2str(i-1)]);
    filename = sprintf('%s/%s/pngs/%slabels-%02d.png', home_dir, dataset, base_fname, i+20-1);
    disp(['reading labels: ' filename]);
    im = double(imread(filename));
    CC = bwconncomp(im);
    L = labelmatrix(CC);
    OldLabels(:,:,i) = L;
    
    if i > 1
        filename1 = sprintf([home_dir '/' dataset '/pngs/' base_fname '%02d.png'], 20+i-2);
        filename2 = sprintf([home_dir '/' dataset '/pngs/' base_fname '%02d.png'], 20+i-1);
        disp(['computing flow: ' filename1 ' ' filename2]);
        im1 = imread(filename1);
        im2 = imread(filename2);
        im1=imfilter(im1,fspecial('gaussian',7,1.0),'same','replicate');
        im2=imfilter(im2,fspecial('gaussian',7,1.0),'same','replicate');
        im1=im2double(im1);
        im2=im2double(im2);

        cellsize=3;
        gridspacing=1;

        sift1 = mexDenseSIFT(im1,cellsize,gridspacing);
        sift2 = mexDenseSIFT(im2,cellsize,gridspacing);

        SIFTflowpara.alpha=2*255;
        SIFTflowpara.d=40*255;
        SIFTflowpara.gamma=0.005*255;
        SIFTflowpara.nlevels=4;
        SIFTflowpara.wsize=1;
        SIFTflowpara.topwsize=10;
        SIFTflowpara.nTopIterations = 60;
        SIFTflowpara.nIterations= 30;

        tic;[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,SIFTflowpara);toc; 
        
        % warp previous labels image with flow field
        warpedPrev = warpImage(Labels(:,:,i-1), -vx, -vy);
        
        for j = 1:length(CC.PixelIdxList)
            flowLabels = arrayfun(@(x) warpedPrev(x), CC.PixelIdxList{j});
            newLabel = mode(flowLabels);
            if newLabel == 0
                newLabel = maxLabel;
                maxLabel = maxLabel + 1;
                disp(['new label added: ' num2str(newLabel)]);
            end
            L(CC.PixelIdxList{j}) = newLabel;
        end
        
    end
    maxLabel = max(L(:)) + 1;
    
    Labels(:,:,i) = L;
end

% figure; imshow(Labels(:,:,2), []); colormap('colorcube');
% figure; imshow(Labels(:,:,3), []); colormap('colorcube');
% figure; imshow(OldLabels(:,:,3), []); colormap('colorcube');
[xi,yi,zi] = meshgrid(1:1:350, 1:1:350, 1:.25:10);
vi = interp3(Labels, xi, yi, zi);
%[x y z] = ind2sub(size(Labels), 1:350*350*10); colors = Labels(:); 
cmpts = find(vi > 0);
[x y z] = ind2sub(size(vi), cmpts);
scatter3(x, y, z, ones(size(x)), cmpts, 'filled');


