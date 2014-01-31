% 
dir = 'isbi_2013';
dataset = 'train';
imgtype = 'pgm';

% for each image
for i = 0:99
    infile = strcat('~/Documents/Research/', dir, '/', imgtype, 's/', ...
        dataset, '-input-', int2str(i), '.', imgtype);
    disp(infile);
    im = imread(infile);

    % normalize
    im_norm = double(im)/double(max(im(:)));
    im_norm = histeq(im_norm);
    
    % other filters
    %im_new = bilateralFilter(im_norm, im_norm, 0.2, 1.0, 96, 0.1);
    %im_new = anisodiff2D(im_norm, 5, 1/7, 1, 1);

    outfile = strcat('~/Documents/Research/', dir, '/', imgtype, 's/', ...
        dataset, '-input-norm-', int2str(i), '.', imgtype);
    imwrite(im_norm, outfile, 'PGM', 'MaxValue', 255);
    %imwrite(im_norm, outfile, imgtype, 'BitDepth', 8, 'XResolution', 1024, 'YResolution', 1024);
end
