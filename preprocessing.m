% 
dir = 'lichtman';
dataset = 'test';
imgtype = 'png';

base_fname = 'Ac3d3nm_export_s';

% for each image
for i = 0:149
    %infile = strcat('~/Documents/Research/', dir, '/', imgtype, 's/', ...
    %    dataset, '-input-', int2str(i), '.', imgtype);
    %infile = sprintf('~/Documents/Research/%s/%ss/%s-volume.tif-%02d.%s', dir, imgtype, dataset, i, imgtype);
    %infile = sprintf('~/Documents/Research/ecs/GreyScaleEM/ECS_aligned_by_Ray_2013_5_3 (1)%04d.tif', i);
    infile = sprintf('~/Documents/Research/%s/pngs/%s%03d.png', dir, base_fname, i);
    disp(infile);
    im = imread(infile);

    % normalize
    %im_norm = double(im)/double(max(im(:)));
    im_norm = histeq(im);
    
    % other filters
    %im_new = bilateralFilter(im_norm, im_norm, 0.2, 1.0, 96, 0.1);
    %im_new = anisodiff2D(im_norm, 5, 1/7, 1, 1);

    %outfile = sprintf('~/Documents/Research/%s/%ss/%s-input-norm-%02d.%s', dir, imgtype, dataset, i, imgtype);
    outfile = sprintf('~/Documents/Research/%s/pngs/Ac3d3nm_norm_s%03d.png', dir, i);
    %imwrite(im_norm, outfile, 'PGM', 'MaxValue', 255);
    imwrite(im_norm, outfile, imgtype, 'BitDepth', 8, 'XResolution', size(im, 1), 'YResolution', size(im,2));
end
