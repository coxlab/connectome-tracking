function [num_splits, num_merges] = num_splits_merges(GT, Pred)
    sz = size(GT, 1);
    numFrames = size(GT, 3);
    max_GT = max(GT(:));
    max_Pred = max(Pred(:));
    numObjs = length(unique(GT(:)));
    
    num_splits = 0;
    num_merges = 0;
    
    for i = 1:max_GT
        Indices = int16(GT == i);
        labels = unique(Pred.*Indices);
        count = length(labels(labels~=0)) - 1; % remove zeros; -1 for correct obj
        
        % don't add it if the count < 0 (this means the index i is not
        % present in the stack)
        if count >= 0
            num_splits = num_splits + count;
        end
    end
    
    counted_labels = [];
    for i = 1:max_Pred
        Indices = int16(Pred == i);
        labels = unique(GT.*Indices);
        filtered_labels = setdiff(labels, counted_labels);
        counted_labels = union(counted_labels, filtered_labels);
        count = length(filtered_labels(filtered_labels~=0)) - 1; % remove zeros; -1 for correct obj
        
        % don't add it if the count < 0 (this means the index i is not
        % present in the stack)
        if count >= 0
            num_merges = num_merges + count;
        end
    end
    
    disp(num_splits);
    disp(num_merges);
    
    num_splits = num_splits/numObjs;     
    num_merges = num_merges/numObjs;
end