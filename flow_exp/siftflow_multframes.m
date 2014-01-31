function siftflow_multframes(idx)
% Function to compute and visualize compounded flow
%	over multiple frames (currently 10).
%	(i.e. for each frame, a pixel's flow value is the displacement between 
%	its current location and its location 10 frames forward.)

	addpath(fullfile(pwd,'../SIFTflow/mexDenseSIFT'));
    addpath(fullfile(pwd,'../SIFTflow/mexDiscreteFlow'));
    addpath(fullfile(pwd,'../SIFTflow'));

	idx = str2num(idx);
	sz = 1024;
	numframes = 100;
	
	base_dir = '../isbi_merged';
	base_fname = 'train-input-norm-';
	
	Boundaries = zeros(sz,sz,numframes);
	Images = zeros(sz,sz,numframes);
	
	for i = 1:numframes
	    filename1 = sprintf('%s/pngs/%s%02d.png', base_dir, base_fname, i-1);
	    im1 = imread(filename1);
	    Boundaries(:,:,i) = im1;
	    
	    im1=imfilter(im1,fspecial('gaussian',7,1.0),'same','replicate');
	    im1=im2double(im1);
	    Images(:,:,i) = im1;
	end
	
	for m = 1:idx
	    TotalVx = zeros(sz,sz);
	    TotalVy = zeros(sz, sz);
	    Dispx = zeros(sz, sz);
	    Dispy = zeros(sz, sz);
	
	    for k = 0:9
	        im1 = Images(:,:,m+k);
	        im2 = Images(:,:,m+k+1);
	
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
	
	        for i = 1:sz
	            for j = 1:sz
	                if i+Dispx(i,j) > 0 && i+Dispx(i,j) < sz+1 && j+Dispy(i,j) > 0 && j+Dispy(i,j) < sz+1
	                    dispx = vx(i+Dispx(i,j), j+Dispy(i,j));
	                    dispy = vy(i+Dispx(i,j), j+Dispy(i,j));
	                    TotalVx(i,j) = TotalVx(i,j) + dispx;
	                    TotalVy(i,j) = TotalVy(i,j) + dispy;
	                    Dispx(i,j) = Dispx(i,j) + dispx;
	                    Dispy(i,j) = Dispy(i,j) + dispy;
	                end
	            end
	        end
	    end
	
	    clear flow;
	    flow(:,:,1) = TotalVx;
	    flow(:,:,2) = TotalVy;
	    flow_field = flowToColor(flow);
	    boundaries = Images(:,:,m);    
	    overlay = imfuse(boundaries, flow_field, 'blend');
	    
	    outfile = sprintf('%s/pngs/flow10_%s%02d.png', base_dir, base_fname, m-1);
	    outfile2 = sprintf('%s/pngs/flow10_overlay_%s%02d.png', base_dir, base_fname, m-1);
	    imwrite(flow_field, outfile, 'PNG', 'BitDepth', 16, 'XResolution', size(flow_field, 1), 'YResolution', size(flow_field,2));
	    imwrite(overlay, outfile2, 'PNG', 'BitDepth', 16, 'XResolution', size(flow_field, 1), 'YResolution', size(flow_field,2));
	end

end

