addpath(fullfile(pwd,'flow_code'));

home_dir = '~/Documents/Research/';
dataset = 'ecs';
% base_fname = 'train-input-norm-';
base_fname = 'ecs350_';
sz = 350;
numFrames = 30;

% for calculating accuracy of a tracked pair between two frames
correct = 0;
total = 0;

% to calculate pct of objs correctly tracked
numObjs = 0;    % num objs present in both frames (in ground truth)
numTrackedObjs = 0;    % num objs tracked correctly in pairs of frames

% % read in labels from multipage tiff to 3D array 'Labels'
% filename = [home_dir '/isbi_2013/train-labels.tif'];
% tiffInfo = imfinfo(filename);
% numFrames = numel(tiffInfo);
Labels = zeros(sz, sz, numFrames);
for i = 1:numFrames
%     im = double(imread(filename,'Index',i,'Info',tiffInfo));
%     Labels(:,:,i) = im(1:sz, 1:sz);
    filename = sprintf('%s/%s/pngs/%slabels-%02d.png', home_dir, dataset, base_fname, i-1);
    Labels(:,:,i) = double(imread(filename));
end

%%
% for each pair of frames
for k = 1:29
    fprintf('frames %d to %d...', k-1, k);
    frame1 = Labels(:,:,k);
    frame2 = Labels(:,:,k+1);
    
    % compute (from ground truth) the num. components that appear in
    %       both frames j and j+1
    objsInFrames = intersect(frame1, frame2);
    numObjs = numObjs + length(objsInFrames);
    
    % arrays to store which objs have been tracked in this pair
    TrackedObjs = zeros(1,401);
    
    filename1 = sprintf('%s/%s/pngs/%s%02d.png', home_dir, dataset, base_fname, k-1);
    filename2 = sprintf('%s/%s/pngs/%s%02d.png', home_dir, dataset, base_fname, k);
    im1_orig = imread(filename1);
    im2_orig = imread(filename2);
    im1_orig = im1_orig(1:sz, 1:sz);
    im2_orig = im2_orig(1:sz, 1:sz);
    im1=imfilter(im1_orig,fspecial('gaussian',7,1.0),'same','replicate');
    im2=imfilter(im2_orig,fspecial('gaussian',7,1.0),'same','replicate');
    im1=im2double(im1);
    im2=im2double(im2); 
    
    uv = estimate_flow_interface(im1, im2, 'classic+nl-fast');
    vx = uv(:,:,1);
    vy = uv(:,:,2);

    TrackedPoints = zeros(sz, sz);
    CorrectPoints = zeros(sz, sz)+0.5;
    CorrectPoints2 = zeros(sz, sz)+0.5;
    [xdim, ydim] = size(im2);
    
    for i = 1:xdim
        for j = 1:ydim
            label1 = frame1(i,j);
            dy = round(vx(i,j)); dx = round(vy(i,j));
            if (i+dx > 0) && (j+dy > 0) && (i+dx < xdim) && (j+dy < ydim)
                label2 = frame2(i+dx,j+dy);
                %TrackedPoints(i+vx(i,j),j+vy(i,j)) = 500;
                TrackedPoints(i+dx,j+dy) = label1;

                total = total + 1;
                if label1 == label2
                    correct = correct + 1;
                    CorrectPoints(i,j) = 1;
                    TrackedObjs(label1 + 1) = TrackedObjs(label1 + 1) + 1;
                else
                    CorrectPoints(i,j) = 0;
                end
            end
            
        end
    end
    numTrackedObjs = numTrackedObjs + length(find(TrackedObjs > 10));
    
    im = CorrectPoints;
%     imwrite(im, sprintf('%s/%s/pngs/siftflow_error_%d.png', home_dir, dataset, k-1), 'PNG', 'BitDepth', 8, 'XResolution', size(im, 1), 'YResolution', size(im,2));
%     imwrite(warpI1, sprintf('%s/%s/pngs/%s%02d-%02d_warped.png', home_dir, dataset, base_fname, k-1, k), 'PNG', 'BitDepth', 16, 'XResolution', size(im, 1), 'YResolution', size(im,2));


%     outfile = sprintf('~/Documents/Research/isbi_merged/pngs/flow2_train-input-norm-%02d-%02d.png', k-1, k);
%     outfile2 = sprintf('~/Documents/Research/isbi_merged/pngs/flow2_overlay_train-input-norm-%02d-%02d.png', k-1, k);
%     imwrite(flow_field, outfile, 'PNG', 'BitDepth', 16, 'XResolution', size(flow_field, 1), 'YResolution', size(flow_field,2));
%     imwrite(overlay, outfile2, 'PNG', 'BitDepth', 16, 'XResolution', size(flow_field, 1), 'YResolution', size(flow_field,2));
end

pctCorrect = correct/total;
pctTrackedObjs = numTrackedObjs/numObjs;

%%
% figure;
% imshow(CorrectPoints);
% figure;
% imshow(CorrectPoints2);
% figure;
% imshow(Labels(:,:,k),[]);
% colormap('colorcube');
% figure;
% imshow(TrackedPoints,[]);
% colormap('colorcube');
% figure;
% imshow(Labels(:,:,k+1),[]);
% colormap('colorcube');

% figure;
% diff = (Labels(:,:,2) == Labels(:,:,1));
% imshow(diff);
% 
% % imshow(Labels(:,:,1), []); colormap('colorcube');
% 
% % figure;
% warpLabels = warpImage(Labels(:,:,1),-vx,-vy);
% % imshow(warpLabels, []); colormap('colorcube');
% 
% figure;
% diff2 = (warpLabels == Labels(:,:,2));
% imshow(diff2);

%%
% figure;
% imshow(Labels(:,:,1));
% figure;
% imshow(warpLabels);
% figure;
% imshow(Labels(:,:,2));
