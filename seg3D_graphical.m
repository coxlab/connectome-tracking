function PredLabels = seg3D_graphical(Seg, EM, sz, numFrames, thresh, Features)
% SEG3D_GRAPHICAL  Given 2D segmentations, produces a 3D labeling.
%   PredLabels = seg3D_graphical(Features, Seg, EM, sz, numFrames, thresh)
%   ...

    % 'Features' is an optional argument, which defaults to 'SIFT'
    if ~exist('Features','var') || isempty(Features)
        Features = 'SIFT';
    end
    
    if strcmp(Features, 'SIFT')
        disp('Using SIFT features.')
        addpath(fullfile(pwd,'SIFTflow/mexDenseSIFT'));
        addpath(fullfile(pwd,'SIFTflow/mexDiscreteFlow'));
        addpath(fullfile(pwd, 'SIFTflow'));
    elseif strcmp(Features, 'CoxLab')
        disp('Using CoxLab features.');
        addpath(fullfile(pwd, 'SIFTflow'));
    else
        error('seg:argChk', 'Invalid value for "Features" argument');
    end
    

    % final labels matrix
    PredLabels = zeros(sz, sz, numFrames);

    % master list of vertices, where Vertices(frame, objNum) gives the
    % corresponding index
    Vertices = spalloc(numFrames, 250, 2000);
    ctr = 0;    % overall counter for vertex indices

    % master list of edges, where each row is [vertex1, vertex2, edge weight]
    Edges = nan(numFrames*250, 2);
    edges_ptr = 1;  % keeps track of the next row in Edges

    % cell array for CC structs (from bwconncomp)
    CCStructs = cell(numFrames, 1);

    %% Getting 2D obj info for first frame -- special case
    
    % first CC and label matrix, for frame 1
    CC_A = bwconncomp(Seg(:,:,1));
    CCStructs{1} = CC_A;

    % Add vertices from first frame to the master list 
    num_obj = CC_A.NumObjects;
    Vertices(1, 1:num_obj) = 1:num_obj;
    ctr = num_obj + 1;

    %% All other frames: 
    
    for i = 2:numFrames
        disp(['getting edges for frames ' num2str(i-1) ' to ' num2str(i)]);
        tic;

        % get CC and labelmatrix info for first frame of pair (already
        % computed)
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
        
        if strcmp(Features, 'SIFT')
            cellsize=3;
            gridspacing=1;
            sift1 = mexDenseSIFT(im1,cellsize,gridspacing);
            sift2 = mexDenseSIFT(im2,cellsize,gridspacing);
        else 
            % TODO: don't hardcode the +7
            fname1 = sprintf('isbi_merged/pngs/train-input-norm-%02d.png', i-1);
            fname2 = sprintf('isbi_merged/pngs/train-input-norm-%02d.png', i);
            sift1 = coxlab_feat(fname1, sz+7);
            sift2 = coxlab_feat(fname2, sz+7);
        end
        
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

        % Add a vertex to the master list for each object in B
        Vertices(i, 1:n) = ctr:(ctr+n-1);
        ctr = ctr + n;
        
        % for each CC in B
        for j = 1:n
            % get (unique) possible corresponding labels
            flowLabels = arrayfun(@(x) warpedForward(x), CC_B.PixelIdxList{j});
            unq = unique(flowLabels);
            unq = unq(unq >= 1);    % ignore 0 and 0.6 (out of frame bounds)

            % get the frequency of each label
            countPerLabel = histc(flowLabels,unq); 
            relFreq = countPerLabel/numel(flowLabels);

            objSize = length(CC_B.PixelIdxList{j});
            Weights(unq, j) = relFreq(:)*objSize;
            Norms(unq, j) = objSize - 1;
        end

        % for each CC in A
        for k = 1:m
            flowLabels = arrayfun(@(x) warpedBackward(x), CC_A.PixelIdxList{k});
            unq = unique(flowLabels);
            unq = unq(unq >= 1);    % ignore 0 and 0.6

            % get the frequency of each label
            countPerLabel = histc(flowLabels,unq); 
            relFreq = countPerLabel/numel(flowLabels); 

            objSize = length(CC_A.PixelIdxList{k});
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

        toc;
    end

    % shrink Edges matrix
    Edges(edges_ptr:end, :) = [];
    ctr = ctr - 1;
    
    %% connect the 3D objects
    
    % create sparse adjacency matrix
    AdjacencyM = sparse(Edges(:,1), Edges(:,2), true, ctr, ctr);

    % get connected components
    [~, C] = graphconncomp(AdjacencyM, 'Weak', true);
    % h = view(biograph(AdjacencyM));

    % for each CC, for each object in the CC, label the pixels
    for i = 1:ctr
       color = C(i);

       [frame, num] = find(Vertices == i);
       Colored = PredLabels(:,:,frame);
       Colored(CCStructs{frame}.PixelIdxList{num}) = color;
       PredLabels(:,:,frame) = Colored; 
    end
    
    PredLabels = int16(PredLabels);

end
