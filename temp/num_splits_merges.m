function [num_splits, num_merges] = num_splits_merges(GT, Pred)
    sz = size(GT, 1);
    numFrames = size(GT, 3);
    max_GT = max(GT(:));
    max_Pred = max(Pred(:));
    numObjs = length(unique(GT(:)));
    
    num_splits = 0;
    num_merges = 0;
    
    for i = 1:max_GT
        Indices = GT == i;
        count = length(unique(Pred.*Indices)) -2; % -1 for zeros 
        if count > 0
            num_splits = num_splits + count;
        end
    end
    
    for i = 1:max_Pred
        Indices = Pred == i;
        count = length(unique(GT.*Indices)) - 2; % -1 for zeros and -1 for correct obj
        if count > 0
            num_merges = num_merges + count;
        end
    end
    
    disp(num_splits);
    disp(num_merges);
    
    num_splits = num_splits/numObjs;     
    num_merges = num_merges/numObjs;
end