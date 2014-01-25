function PredLabels = seg3D_labels_v2(Seg, EM, sz, numFrames, thresh)

    addpath(fullfile(pwd,'/SIFTflow'));
    addpath(fullfile(pwd,'/SIFTflow/mexDenseSIFT'));
    addpath(fullfile(pwd,'/SIFTflow/mexDiscreteFlow'));

%     numFrames = frameEnd - frameStart + 1;

    % final labels matrix
    PredLabels = zeros(sz, sz, numFrames);

    % master list of vertices, where Vertices(frame, objNum) gives the
    % corresponding index
    Vertices = spalloc(numFrames, 250, numFrames*100);
    ctr = 0;    % counter for vertex indices

    % master list of edges, where each row is [vertex1, vertex2, edge weight]
    Edges = nan(numFrames*250, 2);
    edges_ptr = 1;  % keeps track of which row in Edges to continue adding to

    % cell array for CC structs (from bwconncomp)
    CCStructs = cell(numFrames, 1);

    %%
    
    % first CC and label matrix, for frame 1
    CC_A = bwconncomp(Seg(:,:,1));
    CCStructs{1} = CC_A;

    % Add vertices from first frame to the master list
    for i = 1:CC_A.NumObjects
        ctr = ctr + 1;
        Vertices(1, i) = ctr; 
    end

    %%
    for i = 2:numFrames
        disp(['getting edges for frames ' num2str(i-1) ' to ' num2str(i)]);
        tic;

        % get CC and labelmatrix info for first frame of pair
        CC_A = CCStructs{i-1};
        L_A = double(labelmatrix(CC_A));

        % compute CC and labelmatrix for second frame of pair   
        CC_B = bwconncomp(Seg(:,:,i));
        CCStructs{i} = CC_B;
        L_B = double(labelmatrix(CC_B));

        % m = # CCs in A, n = # CCs in B
        m = CC_A.NumObjects; 
        n = CC_B.NumObjects;

        % compute flow between A and B
        im1=imfilter(EM(:,:,i-1),fspecial('gaussian',7,1.0),'same','replicate');
        im2=imfilter(EM(:,:,i),fspecial('gaussian',7,1.0),'same','replicate');
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

        [vx,vy,~]=SIFTflowc2f(sift1,sift2,SIFTflowpara);
        warpedForward = warpImage(L_A, -vx, -vy);
        warpedBackward = warpImage(L_B, vx, vy);

        % Weights is an mxn matrix 
        Weights = spalloc(m,n, floor(m*n/4));
        Norms = ones(m,n);

        % for each CC in B
        for j = 1:n
    %         disp(['CC in frame B #' num2str(j)]);

            % Add a vertex to the master list for each object in B
            ctr = ctr + 1;
            Vertices(i, j) = ctr; 

            % get (unique) possible corresponding labels
            flowLabels = arrayfun(@(x) warpedForward(x), CC_B.PixelIdxList{j});
            unq = unique(flowLabels);
            unq = unq(unq >= 1);    % ignore 0 and 0.6

            % get the frequency of each label
            countPerLabel = histc(flowLabels,unq); 
            relFreq = countPerLabel/numel(flowLabels);

            % [idx of CC in A, idx of CC in B, freq, size of CC in A]
            objSize = length(CC_B.PixelIdxList{j});
    %         Weights(j, unq) = Weights(j, unq) + relFreq*objSize;
    %         Norms(j, unq) = Norms(j, unq) + objSize;

%             v1 = full(Vertices(i-1,unq));
    %         freqs = [v1(:), ones(length(unq),1)*ctr, relFreq(:)*objSize, ones(length(unq), 1)*objSize];
    %         data = [data; freqs];j
    %         Weights(v1(:), ctr) = relFreq(:)*objSize;
    %         Norms(v1(:), ctr) = objSize;
            Weights(unq, j) = relFreq(:)*objSize;
            Norms(unq, j) = objSize - 1;
        end

    %     Weights = sparse(data(:,1), data(:,2), data(:,3));
    %     Norms = sparse(data(:,1), data(:,2), data(:,4)); % normalizing denom

        % for each CC in A
        for k = 1:m
    %         disp(['CC in frame A #' num2str(k)]);

            flowLabels = arrayfun(@(x) warpedBackward(x), CC_A.PixelIdxList{k});
            unq = unique(flowLabels);
            unq = unq(unq >= 1);    % ignore 0 and 0.6

            % get the frequency of each label
            countPerLabel = histc(flowLabels,unq); 
            relFreq = countPerLabel/numel(flowLabels); 

            objSize = length(CC_A.PixelIdxList{k});
%             v1 = Vertices(i-1, k);
%             v2 = full(Vertices(i, unq));
    %         Weights(v1, v2) = Weights(v1, v2) + relFreq'*objSize;
    %         Norms(v1, v2) = Norms(v1, v2) + objSize;
            Weights(k, unq) = Weights(k,unq) + relFreq(:)'*objSize;
            Norms(k,unq) = Norms(k,unq) + objSize;
        end

        % normalize everything, then add to master list of edges
        Weights = Weights ./ Norms;
        Weights = Weights > thresh;
        [x,y,~] = find(sparse(Weights));
        x = full(Vertices(i-1, x));
        y = full(Vertices(i, y));
        Edges(edges_ptr:edges_ptr+length(x)-1, :) = [x(:), y(:)];
        edges_ptr = edges_ptr + length(x);

    %     CC_A = CC_B;
    %     L_A = L_B;
        toc;
    end

    % shrink Edges matrix
    Edges(edges_ptr:end, :) = [];
    
    %%
    % create sparse adjacency matrix
    AdjacencyM = sparse(Edges(:,1), Edges(:,2), true, ctr, ctr);

    % get connected components
    [~, C] = graphconncomp(AdjacencyM, 'Weak', true);
    % h = view(biograph(AdjacencyM));

    % for each CC, for each object in the CC, label the pixels
    for i = 1:ctr
       color = C(i);

       [frame, num] = find(Vertices == i);
%        [xs, ys] = ind2sub([sz sz], CCStructs{frame}.PixelIdxList{num});
       Colored = PredLabels(:,:,frame);
       Colored(CCStructs{frame}.PixelIdxList{num}) = color;
       PredLabels(:,:,frame) = Colored; 
    end

end
