function computeSiftFeatures(peakthresh, edgethresh)

		run('/n/home08/vtan/vlfeat-0.9.16/toolbox/vl_setup');

    peakthresh = str2double(peakthresh);
    edgethresh = str2double(edgethresh);

    for i = 0:99
        infile = sprintf('/n/home08/vtan/isbi_2013/pgms/train-input-norm-%d.pgm', i);
        im = double(imread(infile));

        % sift features
        F = vl_sift(single(im), 'PeakThresh', peakthresh, ...
            'EdgeThresh', edgethresh);
        numFeatures = length(F(1,:));

        % create output file
        outfile = sprintf('/n/home08/vtan/klt/sift_features/init_feat%d.txt', i);
        disp(outfile);
        fout = fopen(outfile, 'w+');
        fprintf(fout, '!!! Warning:  This is a KLT data file.  Do not modify below this line !!!\n\n');
        fprintf(fout, '------------------------------\nKLT Feature Table\n------------------------------\n\n');
        fprintf(fout, 'nFrames = 1, nFeatures = %d\n\n', numFeatures);
        fprintf(fout, 'feature |          frame\n\t\t|\t\t 0\n');
        fprintf(fout, '--------+--------------------------------------------------------------------\n');
        val = 1;
        for j = 1:numFeatures
            x = F(1,j);
            y = F(2,j);
            fprintf(fout, '\t  %d | (%f, %f)=\t %d\n', j-1, x, y, val);
        end

        fclose(fout);
    end
end


