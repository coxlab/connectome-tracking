function [PredLabels, GT, rand_err, VI, num_splits, num_merges] = eval_seg3D(sz, thresh, frameStart, frameEnd)
%     addpath('/n/home08/vtan/matlab_src/mi');
    addpath(fullfile(pwd, 'mi'));
    
%     home_dir = '/n/home08/vtan';
    home_dir = '~/Documents/Research';
    dataset = 'isbi_merged';
    base_fname = 'train-';
    numFrames = frameEnd - frameStart + 1;

    % load all label images, segmented images and EM images
    GT = zeros(sz, sz, numFrames);
    Seg = zeros(sz, sz, numFrames);
    EM = zeros(sz, sz, numFrames);
    for i = frameStart:frameEnd
        idx = i - frameStart + 1;
        
        disp(['reading images frame ' num2str(i-1)]);
        im1 = double(imread([home_dir '/isbi_2013/pngs/train-labels-' num2str(i-1) '.png']));
        GT(:,:,idx) = im1(1:sz,1:sz);
        im2 = double(imread(sprintf('%s/%s/pngs/%slabels.tif-%02d.png', home_dir, dataset, base_fname, i-1)));
        Seg(:,:,idx) = im2(1:sz,1:sz);
        im3 = double(imread(sprintf([home_dir '/' dataset '/pngs/' base_fname 'input-norm-%02d.png'], i-1)));
        EM(:,:,idx) = im3(1:sz, 1:sz);
    end
    
    PredLabels = seg3D_labels_v2(Seg, EM, sz, numFrames, thresh);
    
    rand_err = SNEMI3D_metrics(GT, PredLabels);
    VI = entropy(GT) + entropy(PredLabels) - 2*mutualinfo(GT, PredLabels);
    [num_splits, num_merges] = num_splits_merges(GT, PredLabels);
end
