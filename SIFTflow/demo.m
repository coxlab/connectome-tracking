filename = '~/Documents/Research/isbi_2013/train-labels.tif';
tiffInfo = imfinfo(filename);
numFrames = numel(tiffInfo);
Labels = zeros(1024, 1024, numFrames);
for i = 1:numFrames
    Labels(:,:,i) = double(imread(filename,'Index',i,'Info',tiffInfo));
end

im1=imread('~/Documents/Research/isbi_merged/pngs/train-input-norm-07.png');
im2=imread('~/Documents/Research/isbi_merged/pngs/train-input-norm-08.png');
%im1=imread('~/Documents/Research/ecs/pngs/ecs5-3_02.png');
%im2=imread('~/Documents/Research/ecs/pngs/ecs5-3_03.png');

im1=imfilter(im1,fspecial('gaussian',7,1.0),'same','replicate');
im2=imfilter(im2,fspecial('gaussian',7,1.0),'same','replicate');
%im1=imresize(imfilter(im1,fspecial('gaussian',7,1.0),'same','replicate'),0.5,'bicubic');
%im2=imresize(imfilter(im2,fspecial('gaussian',7,1.0),'same','replicate'),0.5,'bicubic');

im1=im2double(im1);
im2=im2double(im2);

%figure;imshow(im1);figure;imshow(im2);

cellsize=3;
gridspacing=1;

%addpath(fullfile(pwd,'mexDenseSIFT'));
%addpath(fullfile(pwd,'mexDiscreteFlow'));

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


tic;[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,SIFTflowpara);toc

warpI2=warpImage(im2,vx,vy);
%figure;imshow(im1);
%figure;imshow(im2);
%figure;imshow(warpI2);

% display flow
clear flow;
flow(:,:,1)=vx;
flow(:,:,2)=vy;
%figure;imshow(flowToColor(flow));

correct = 0;
total = 0;
TrackedPoints = zeros(1024, 1024);
[xdim ydim] = size(im2);
for i = 1:xdim
    for j = 1:ydim
        label1 = Labels(i,j,7);
        if (i+vx(i,j) > 0) && (j+vy(i,j) > 0) && (i+vx(i,j) < xdim) && (j+vy(i,j) < ydim)
            label2 = Labels(i+vx(i,j),j+vy(i,j), 8);
            total = total + 1;
            if label1 == label2
                correct = correct + 1;
                TrackedPoints(i,j) = 1;
            end
        end
        
    end
end

disp(correct/total);
imshow(TrackedPoints);

return;

% this is the code doing the brute force matching
tic;[flow2,energylist2]=mexDiscreteFlow(Sift1,Sift2,[alpha,alpha*20,60,30]);toc
figure;imshow(flowToColor(flow2));
