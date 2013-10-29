addpath(fullfile(pwd,'mexDenseSIFT'));
addpath(fullfile(pwd,'mexDiscreteFlow'));

% for calculating accuracy of a tracked pair between two frames
correct = 0;
total = 0;

% to calculate pct of objs correctly tracked
numObjs = 0;    % num objs present in both frames (in ground truth)
numTrackedObjs = 0;    % num objs tracked correctly in pairs of frames

% read in labels from multipage tiff to 3D array 'Labels'
filename = '/n/home08/vtan/isbi_2013/train-labels.tif';
tiffInfo = imfinfo(filename);
numFrames = numel(tiffInfo);
Labels = zeros(1024, 1024, numFrames);
for i = 1:numFrames
    Labels(:,:,i) = double(imread(filename,'Index',i,'Info',tiffInfo));
end

% for each pair of frames
for k = 1:99
    frame1 = Labels(:,:,k);
    frame2 = Labels(:,:,k+1);
    
    % compute (from ground truth) the num. components that appear in
    %       both frames j and j+1
    %objsInFrames = intersect(frame1, frame2);
    %numObjs = numObjs + length(objsInFrames);
    
    % arrays to store which objs have been tracked in this pair
    %TrackedObjs = zeros(1,401);
    
    filename1 = sprintf('/n/home08/vtan/isbi_merged/pngs/train-input-norm-%02d.png', k-1);
    filename2 = sprintf('/n/home08/vtan/isbi_merged/pngs/train-input-norm-%02d.png', k);
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
    warpI2=warpImage(im2,vx,vy);
    warpI1=warpImage(im1,-vx,-vy);
    
    clear flow;
    flow(:,:,1)=vx;
    flow(:,:,2)=vy;
    flow_field = flowToColor(flow);
    %figure;
    %imshow(flow_field);
    %figure;
    b = sprintf('/n/home08/vtan/isbi_merged/pngs/train-labels.tif-%02d.png', k-1);
    boundaries = imread(b);
    overlay = imfuse(boundaries, flow_field, 'blend');
    %imshow(overlay);


%     TrackedPoints = zeros(1024, 1024);
%     CorrectPoints = zeros(1024, 1024);
%     [xdim ydim] = size(im2);
%     for i = 1:xdim
%         for j = 1:ydim
%             label1 = frame1(i,j);
%             if (i+vx(i,j) > 0) && (j+vy(i,j) > 0) && (i+vx(i,j) < xdim) && (j+vy(i,j) < ydim)
%                 label2 = frame2(i+vx(i,j),j+vy(i,j));
%                 %TrackedPoints(i+vx(i,j),j+vy(i,j)) = 500;
%                 TrackedPoints(i+vx(i,j),j+vy(i,j)) = label1;
% 
%                 total = total + 1;
%                 if label1 == label2
%                     correct = correct + 1;
%                     CorrectPoints(i,j) = 1;
%                     TrackedObjs(label1 + 1) = TrackedObjs(label1 + 1) + 1;
%                 end
%             end
%             
%         end
%     end
%     numTrackedObjs = numTrackedObjs + length(find(TrackedObjs > 20));

    outfile = sprintf('/n/home08/vtan/isbi_merged/pngs/flow2_train-input-norm-%02d-%02d.png', k-1, k);
    outfile2 = sprintf('/n/home08/vtan/isbi_merged/pngs/flow2_overlay_train-input-norm-%02d-%02d.png', k-1, k);
    imwrite(flow_field, outfile, 'PNG', 'BitDepth', 16, 'XResolution', size(flow_field, 1), 'YResolution', size(flow_field,2));
    imwrite(overlay, outfile2, 'PNG', 'BitDepth', 16, 'XResolution', size(flow_field, 1), 'YResolution', size(flow_field,2));
end

% pctCorrect = correct/total;
% pctTrackedObjs = numTrackedObjs/numObjs;

% figure;
% imshow(CorrectPoints);
% figure;
% imshow(TrackedPoints,[]);
% colormap('colorcube');

% im = CorrectPoints;
% imwrite(im, '/n/home08/vtan/isbi_merged/pngs/siftflow_error.png', 'PNG', 'BitDepth', 8, 'XResolution', size(im, 1), 'YResolution', size(im,2));
% imwrite(warpI1, '/n/home08/vtan/isbi_merged/pngs/train-input-norm-09-10_warped.png', 'PNG', 'BitDepth', 16, 'XResolution', size(im, 1), 'YResolution', size(im,2));

