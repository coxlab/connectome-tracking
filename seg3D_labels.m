addpath(fullfile(pwd,'mexDenseSIFT'));
addpath(fullfile(pwd,'mexDiscreteFlow'));

home_dir = '/n/home08/vtan';
% dataset = 'ecs';
dataset = 'isbi_merged';
base_fname = 'train-';
% base_fname = 'ecs350_';
sz = 512;

% current max label
maxLabel = 0;

numFrames = 100;

for i = 1:100

end

% read in labels
GT = zeros(sz, sz, numFrames);
Labels = zeros(sz, sz, numFrames);

for i = 1:numFrames
    im = double(imread(['/n/home08/vtan/isbi_2013/pngs/train-labels-' num2str(i-1) '.png']));
    GT(:,:,i) = im(1:512,1:512);
    
    disp(['frame ' num2str(i-1)]);
    filename = sprintf('%s/%s/pngs/%slabels.tif-%02d.png', home_dir, dataset, base_fname, i-1);
    disp(['reading labels: ' filename]);
    im = double(imread(filename));
    im = im(1:sz,1:sz);
    
    CC = bwconncomp(im);
    L = labelmatrix(CC);
    L = uint16(L);
    
%     b = bwperim(im);
%     CC2 = bwconncomp(b);
%     B = labelmatrix(CC2);
    
    if i > 1
        filename1 = sprintf([home_dir '/' dataset '/pngs/' base_fname 'input-norm-%02d.png'], i-2);
        filename2 = sprintf([home_dir '/' dataset '/pngs/' base_fname 'input-norm-%02d.png'], i-1);
        disp(['computing flow: ' filename1 ' ' filename2]);
        im1 = imread(filename1); im1 = im1(1:sz, 1:sz);
        im2 = imread(filename2); im2 = im2(1:sz, 1:sz);
        im1=imfilter(im1,fspecial('gaussian',7,1.0),'same','replicate');
        im2=imfilter(im2,fspecial('gaussian',7,1.0),'same','replicate');
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

        tic;[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,SIFTflowpara);toc; 
        
        % warp previous labels image with flow field
        warpedPrev = warpImage(Labels(:,:,i-1), -vx, -vy);
        
        for j = 1:length(CC.PixelIdxList)
            flowLabels = arrayfun(@(x) warpedPrev(x), CC.PixelIdxList{j});
            unq = unique(flowLabels);
            unq = unq(unq >= 1);

            countElA=histc(flowLabels,unq); % get the count of elements
            relFreq=countElA/numel(flowLabels);
                        
            if length(unq) < 1
%                 newLabel = maxLabel;
%                 maxLabel = maxLabel + 1;
                [xt,yt] = ind2sub(size(L), CC.PixelIdxList{j}(1));
                newLabel = GT(xt,yt,i); 
                disp(['new label added: ' num2str(newLabel)]);
            else
                [freq, idx] = max(relFreq);
                if freq > 0.4
                    newLabel = unq(idx);
                else
%                     newLabel = maxLabel;
%                     maxLabel = maxLabel + 1;
                    [xt,yt] = ind2sub(size(L), CC.PixelIdxList{j}(1));
                    newLabel = GT(xt,yt,i); 
                    disp(['new label added: ' num2str(newLabel)]);
                end
            end
            L(CC.PixelIdxList{j}) = newLabel;
        end
    else
%         maxLabel = max(L(:)) + 1;
        L = GT(:,:,i);
    end
    
    Labels(:,:,i) = L;
end

%% write labels to file

% t = Tiff([home_dir '/' dataset '/res/' base_fname' 'gt-labels.tif'], 'w');
% t.setTag('Photometric',Tiff.Photometric.MinIsBlack);
% t.setTag('Compression',Tiff.Compression.None);
% t.setTag('BitsPerSample',32);
% t.setTag('SamplesPerPixel',1);
% t.setTag('SampleFormat',Tiff.SampleFormat.IEEEFP);
% t.setTag('ExtraSamples',Tiff/ExtraSamples.Unspecified);
% t.setTag('ImageLength',350);
% t.setTag('ImageWidth',350);
% t.setTag('TileLength',32);
% t.setTag('TileWidth',32);
% t.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
% 
% t.close();

% for i = 1:10
%     imwrite(Labels(:,:,i), [home_dir '/' dataset '/res/' base_fname 'gt-labels.tif'], 'WriteMode', 'append', 'Compression', 'none');
% end

% save([home_dir '/' dataset '/res/ecs350_gt-labels.mat'], 'Labels');
save([home_dir '/' dataset '/res/isbi13_gt-labels.mat'], 'Labels');

