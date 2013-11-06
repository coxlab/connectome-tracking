function [Pred, GT, rand_err, VI, num_splits, num_merges] = eval_seg3D(sz, thresh, frameStart, frameEnd)
    %addpath('/n/home08/vtan/matlab_src/mi');
    
    home_dir = '/vtan/connectome-tracking';
    dataset = 'isbi_merged';
    base_fname = 'train-';
    numFrames = frameEnd - frameStart + 1;

    % load all label images, segmented images and EM images
    GT = zeros(sz, sz, numFrames); % 3D ground truth labels
    Seg = zeros(sz, sz, numFrames); % 2D ground truth segmentation
    EM = zeros(sz, sz, numFrames); % actual images
    for i = frameStart:frameEnd
        idx = i - frameStart + 1; % the index for GT, Seg, EM
        
        disp(['reading images frame ' num2str(i-1)]);
        im1 = double(imread([home_dir '/isbi_2013/pngs/train-labels-' num2str(i-1) '.png']));
        GT(:,:,idx) = im1(1:sz,1:sz);
        im2 = double(imread(sprintf('%s/%s/pngs/%slabels.tif-%02d.png', home_dir, dataset, base_fname, i-1)));
        Seg(:,:,idx) = im2(1:sz,1:sz);
        im3 = double(imread(sprintf([home_dir '/' dataset '/pngs/' base_fname 'input-norm-%02d.png'], i-1)));
        EM(:,:,idx) = im3(1:sz, 1:sz);
    end
    
    GT = int16(GT);
    Pred = seg3D_labels_v2(Seg, EM, sz, numFrames, thresh);  % returns int16
    
    rand_err = SNEMI3D_metrics(GT, Pred);
    %VI = entropy(GT) + entropy(double(PredLabels)) - 2*mutualinfo(GT, PredLabels);
    VI = 0;
    [num_splits, num_merges] = num_splits_merges(GT, Pred);
end

function e = vector_entropy(v)
    e = -sum(v .* log2(v));
end

function je = joint_entropy(v1, v2) 
    % changes values from [min, max] to [1, max-min]
    total_min = min(min(v1),min(v2));
    v1 = v1 - total_min + 1;
    v2 = v2 - total_min + 1;
    upper = max(max(v1),max(v2));

    n = numel(v1);
    idx = 1:n;  % v1 and v2 same size
    p = nonzeros(sparse(idx,v1,1,n,upper,n)'*sparse(idx,v2,1,n,upper,n)/n); %joint distribution of x and y

    je = -dot(p,log2(p+eps));
end

function mi = mutualInformation(v1, v2)
    %mi = vector_entropy(v1) + vector_entropy(v1) - joint_entropy(v1, v2);
end