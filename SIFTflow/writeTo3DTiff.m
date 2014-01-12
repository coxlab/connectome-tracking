function writeTo3DTiff(data, fname)
    t = Tiff(fname, 'w');
    t.close();
    
    for i = 1:size(data, 3)
        t = Tiff(fname, 'a');
        t.setTag('Photometric',Tiff.Photometric.MinIsBlack);
        t.setTag('Compression',Tiff.Compression.None);
        t.setTag('BitsPerSample',16);
        t.setTag('SamplesPerPixel',1);
        t.setTag('SampleFormat',Tiff.SampleFormat.Int);
        t.setTag('ImageLength',1024);
        t.setTag('ImageWidth',1024);
        %t.RowsPerStrip = 16;
        %t.setTag('TileLength',32);
        %t.setTag('TileWidth',32);
        t.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);

        t.write(data(:, :, i));
        t.close();
    end
end