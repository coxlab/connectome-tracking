function [Pred, GT, rand_err, VI, num_splits, num_merges] = eval_seg3D(sz, thresh, frameStart, frameEnd)
% EVAL_SEG3D Predicts a 3D labeling for the ISBI dataset from 2D ground
% truth, evaluating by 4 metrics.
%   [Pred, GT, rand_err, VI, num_splits, num_merges] = eval_seg3D(sz, thresh, frameStart, frameEnd)
% 
%   Inputs:
%       sz - Desired dimension of image (for cropping)
%       thresh - An experimentally determined threshold for clustering the
%       graph (determined by cross-validation)
%       frameStart - First image in stack to use [1, 100]
%       frameEnd - Last image in stack to use [1,100]
%   Outputs:
%       Pred - Predicted labels for 3D reconstruction
%       GT - Ground truth labels of 3D reconstruction
%       rand_err - Rand error as defined by the ISBI 2013 challenge
%       VI - Variation of information between Pred and GT
%       num_splits - Split error (number of splits per object)
%       num_merges - Merge error (number of merges per object)
    
    home_dir = '~/connectome-tracking';
    dataset = 'isbi_merged';
    base_fname = 'train-';
    numFrames = frameEnd - frameStart + 1;

    % load all label images, segmented images and EM images
    GT = zeros(sz, sz, numFrames); % 3D ground truth labels
    Seg = zeros(sz, sz, numFrames); % 2D ground truth segmentation
    EM = zeros(sz, sz, numFrames); % actual images
    
    fprintf('Reading images %d to %d.\n', frameStart-1, frameEnd-1);
    for i = frameStart:frameEnd
        idx = i - frameStart + 1; % the index for GT, Seg, EM
        
        im1 = double(imread([home_dir '/isbi_2013/pngs/train-labels-' num2str(i-1) '.png']));
        GT(:,:,idx) = im1(1:sz,1:sz);
        im2 = double(imread(sprintf('%s/%s/pngs/%slabels.tif-%02d.png', home_dir, dataset, base_fname, i-1)));
        Seg(:,:,idx) = im2(1:sz,1:sz);
        im3 = double(imread(sprintf([home_dir '/' dataset '/pngs/' base_fname 'input-norm-%02d.png'], i-1)));
        EM(:,:,idx) = im3(1:sz, 1:sz);
    end
    
    GT = int16(GT);
    Pred = seg3D_graphical(Seg, EM, sz, numFrames, thresh, 'CoxLab');  % returns int16
    
    rand_err = SNEMI3D_metrics(GT, Pred);
    %VI = entropy(GT) + entropy(double(PredLabels)) - 2*mutualinfo(GT, PredLabels);
    VI = vector_entropy(GT(:)) + vector_entropy(Pred(:)) - 2*mutualInformation(GT(:), Pred(:));
    [num_splits, num_merges] = num_splits_merges(GT, Pred);
    
    fileID = fopen('foo.txt','a');
    fprintf(fileID,'thresh: %f\n', thresh);
    fprintf(fileID,'rand: %f, VI: %f, splits: %f, merges: %f\n', rand_err, VI, num_splits, num_merges);
    fclose(fileID);
end

function e = vector_entropy(v)
    v = double(v);
    p = hist(v, max(v))/numel(v);
    p(p==0) = [];
    e = -sum(p .* log2(p));
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
    v1 = double(v1);
    v2 = double(v2);
    mi = vector_entropy(v1) + vector_entropy(v1) - joint_entropy(v1, v2);
end