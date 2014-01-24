function effmap = coxlab_feat(file, size)

    %size = 500;
    %systemCommand = ['python slmsimple_args.py ', 'isbi_merged/pngs/train-input-norm-00.png ', num2str(size)];
    systemCommand = ['python slmsimple_args.py ', file, ' ', num2str(size)];
    [status, result] = system(systemCommand);

    
    if (~status)
        load('fmap.mat');
        effmap = fullfm(fmap, size);
        
        % crop and normalize (?)
        effmap = effmap(1:size-7, 1:size-7, :);
        effmap = uint8(mat2gray(effmap)*255);
    end
    
    
    %figure; imshow(effmap, []);

end
