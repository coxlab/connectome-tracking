function [truePairs, pctTruePairs, pctHitObjs, pctTrackedObjs,...
    pctSmallTrackedObjs]=evalTrackedPoints(method) 

		home_dir = '/n/home08/vtan';

    % for calculating accuracy of a tracked pair between two frames
    correctPairs = 0;
    incorrectPairs = 0;
    
    % to calculate pct of objs correctly tracked
    numObjs = 0;    % num objs present in both frames (in ground truth)
    numHitObjs = 0;   % num objs that are detected in the first frame of a 
                    	%   pair of frames*

    numTrackedObjs = 0;    % num objs tracked correctly in pairs of frames
    	%   *given that the obj is present in both frames in ground truth
    
    % read in labels from multipage tiff to 3D array 'Labels'
    filename = [home_dir '/isbi_2013/train-labels.tif';
    tiffInfo = imfinfo(filename);
    numFrames = numel(tiffInfo);
    Labels = zeros(1024, 1024, numFrames);
    for i = 1:numFrames
        Labels(:,:,i) = double(imread(filename,'Index',i,'Info',tiffInfo));
    end

    Files = zeros(40000, 5, numFrames-1);
    % for each pair of frames
    for j = 1:numFrames-1
        frame1 = Labels(:,:,j);
        frame2 = Labels(:,:,j+1);
        
        % compute (from ground truth) the num. components that appear in 
        %       both frames j and j+1
        objsInFrames = intersect(frame1, frame2);
        numObjs = numObjs + length(objsInFrames);
        
        % read in from file the tracked features between frames j and j+1
        filename = sprintf([home_dir '/klt/%s_features/features%d-%d.csv'], method, j-1, j);
        disp(filename);
        F = csvread(filename);
        xs = F(:,1);
        ys = F(:,2);
        Files(1:size(F,1), 1:size(F,2),j) = F;
        
        % arrays to store which objs have been tracked in this pair
        HitObjs = zeros(1,401);
        TrackedObjs = zeros(1,401);
        
        % for each tracked feature point
        for i = 1:2:length(xs)-1
            currentFrameLabel = Labels(round(xs(i)), round(ys(i)), j);
            
            % if this point is in a obj that appears in both frames, 
            %       it counts as a 'hit'
            if any(currentFrameLabel==objsInFrames)
                HitObjs(currentFrameLabel + 1) = 1;
            end
            
            
            % if the point was successfully tracked to the next frame
            if xs(i+1) ~= 1
                nextFrameLabel = Labels(round(xs(i+1)), round(ys(i+1)), j+1);
                
                % if the labels match
                if currentFrameLabel == nextFrameLabel
                    correctPairs = correctPairs + 1;
                    TrackedObjs(currentFrameLabel + 1) = 1;
                else
                    incorrectPairs = incorrectPairs + 1;
                end
            end
        end
        
        % sum up the number of objs hit/tracked in this pair of frames
        numHitObjs = numHitObjs + sum(HitObjs);
        numTrackedObjs = numTrackedObjs + sum(TrackedObjs);
    end

    % metrics
    truePairs = correctPairs;
    pctTruePairs = correctPairs/(correctPairs + incorrectPairs);
    pctHitObjs = numHitObjs/numObjs;
    pctTrackedObjs = numTrackedObjs/numObjs;
    
    fout = fopen([home_dir '/klt/' method '-metrics.txt'], 'a');
    fprintf(fout, strcat(num2str(truePairs), '\t'));
    fprintf(fout, strcat(num2str(pctTruePairs), '\t'));
    fprintf(fout, strcat(num2str(pctHitObjs), '\t'));
    fprintf(fout, strcat(num2str(pctTrackedObjs), '\t'));
   
		% compute metrics regarding percent of "small" objects tracked
    for k = 0.05:0.05:0.25
       pctSmallTrackedObjs = smallObjMetrics(k, Files);
       fprintf(fout, strcat(num2str(pctSmallTrackedObjs), '\t'));
    end
    fprintf(fout, '\n')
    
    fclose(fout);

end
