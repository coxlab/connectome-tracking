addpath(fullfile(pwd,'mexDenseSIFT'));
addpath(fullfile(pwd,'mexDiscreteFlow'));

home_dir = '/home/vtan/connectome-tracking/retina';
base_image = 10;
num_frames = 50;

% for each pair of frames
filename1 = sprintf([home_dir '/Overviews_%04d.png'], base_image);
im1 = imread(filename1);
im1=imresize(imfilter(im1,fspecial('gaussian',7,1.0),'same','replicate'),0.25,'bicubic');
im1=im2double(im1);

for i = 1:num_frames
    if i ~= base_image
        filename2 = sprintf([home_dir '/Overviews_%04d.png'], i);
        im2 = imread(filename2);
        im2=imresize(imfilter(im2,fspecial('gaussian',7,1.0),'same','replicate'),0.25,'bicubic');
        im2=im2double(im2);

        cellsize=5;
        gridspacing=1;

        sift1 = mexDenseSIFT(im1,cellsize,gridspacing);
        sift2 = mexDenseSIFT(im2,cellsize,gridspacing);

        SIFTflowpara.alpha=2*255; % was 2*255
        SIFTflowpara.d=40*255;
        SIFTflowpara.gamma=0.00*255; % ws .005*255
        SIFTflowpara.nlevels=4;
        SIFTflowpara.wsize=1;
        SIFTflowpara.topwsize=10;
        SIFTflowpara.nTopIterations = 60;
        SIFTflowpara.nIterations= 30;

        tic;[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,SIFTflowpara);toc; 
        warpI2=warpImage(im2,vx,vy);
        %warpI1=warpImage(im1,-vx,-vy);

        clear flow;
%         figure;
%         imshow(im1);
%         figure;
%         imshow(im2);
%         figure;
%         imshow(warpI2);
        
        outfile = sprintf([home_dir '/Overviews_%04d_warped.png'], i);
        imwrite(warpI2, outfile, 'PNG', 'BitDepth', 16, 'XResolution', size(warpI2, 1), 'YResolution', size(warpI2,2));
        
    end
    

    
end

