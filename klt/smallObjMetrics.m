function pctSmallTrackedObjs=smallObjMetrics(pctSmall, Files)   
    % to calculate pct of small objects correctly tracked
    numSmallObjs = 0;
    numSmallTrackedObjs = 0;

    % read in labels from multipage tiff to 3D array 'Labels'
    filename = '~/Documents/Research/isbi_2013/train-labels.tif';
    tiffInfo = imfinfo(filename);
    numFrames = numel(tiffInfo);
    Labels = zeros(1024, 1024, numFrames);
    for i = 1:numFrames
        Labels(:,:,i) = double(imread(filename,'Index',i,'Info',tiffInfo));
    end
    %numLabels = length(unique(Labels(:)));

    % for each pair of frames
    for j = 1:numFrames-1
        frame1 = Labels(:,:,j);
        frame2 = Labels(:,:,j+1);
        
        % compute (from ground truth) the num. components that appear in 
        %       both frames j and j+1
        objsInFrames = intersect(frame1, frame2);
        %numObjs = numObjs + length(objsInFrames);
         
        % rank the objects in the first frame by increasing size
        [Count, ObjLabel] = hist(frame1(:), objsInFrames);
        SortedObjCounts = sortrows([Count(:) ObjLabel]);
    
        % indices of the smallest 25% of 2D object slices in the frame
        SmallObjs = SortedObjCounts(1:round(length(Count)*pctSmall), 2);
        numSmallObjs = numSmallObjs + length(SmallObjs);
        
        % read in from file the tracked features between frames j and j+1
        %filename = sprintf('~/Documents/Research/connectome-tracking/%s_features/features%d-%d.csv', dataset, j-1, j);
        %disp(filename);
        %F = csvread(filename);    
        F = Files(:,:,j);
        xs = F(:,1);
        ys = F(:,2);
        
        % arrays to store which objs have been tracked in this pair
        SmallTrackedObjs = zeros(1,401);
        
        % for each tracked feature point
        for i = 1:2:length(xs)-1
            if xs(i) == 0 || xs(i+1) == 0
               break 
            end
            currentFrameLabel = Labels(round(xs(i)), round(ys(i)), j);
                
            % if the point was successfully tracked to the next frame
            if xs(i+1) ~= 1
                nextFrameLabel = Labels(round(xs(i+1)), round(ys(i+1)), j+1);
                
                % if the labels match
                if currentFrameLabel == nextFrameLabel
                    if any(currentFrameLabel==SmallObjs)
                        SmallTrackedObjs(currentFrameLabel + 1) = 1;
                    end
                end
            end
        end
        
        % sum up the number of objs hit/tracked in this pair of frames
        numSmallTrackedObjs = numSmallTrackedObjs + sum(SmallTrackedObjs);
    end

    % metrics
    pctSmallTrackedObjs = numSmallTrackedObjs/numSmallObjs;
    
    %fout = fopen('~/Documents/Research/connectome-tracking/pipeline-test.txt', 'a');
    %fprintf(fout, strcat(num2str(pctSmallTrackedObjs), '\n'));
    %fclose(fout);

end
