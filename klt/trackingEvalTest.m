% read in labels from multipage tiff to 3D array 'Labels'
filename = '~/Documents/Research/isbi_2013/train-labels.tif';
tiffInfo = imfinfo(filename);
numFrames = numel(tiffInfo);
Labels = zeros(1024, 1024, numFrames);
for i = 1:numFrames
    Labels(:,:,i) = double(imread(filename,'Index',i,'Info',tiffInfo));
end
%numLabels = length(unique(Labels(:)));

areas = zeros(1,98);
minareas = zeros(1,98);

% for each pair of frames
for j = 1:98
    % compute (from ground truth) the num. components that appear in 
    %       both frames j and j+1
    frame1 = Labels(:,:,j);
    frame2 = Labels(:,:,j+1);
    objsInFrames = intersect(frame1, frame2);

    [Count, ObjLabel] = hist(frame1(:), objsInFrames);
    SortedObjCounts = sortrows([Count(:) ObjLabel]);
    
    SmallObjs = SortedObjCounts(1:round(length(Count)/4), 2);
    areas(j) = SortedObjCounts(round(length(Count)/4), 1);
    minareas(j) = SortedObjCounts(1, 1);
    disp(length(Count));
    
end

disp(areas);
disp(minareas);
