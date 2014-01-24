function vis3D(Frames)
%     home_dir = '/n/home08/vtan';
%     dataset = 'isbi_merged';
%     sz = 512;
%     num_frames = 100;
%     S = load([home_dir '/' dataset '/res/isbi13_gt-labels.mat']);
%     Frames = S.Labels;

    sz = size(Frames, 1);
    num_frames = size(Frames, 3);
    Frames = double(Frames);
    
    figure; 
    hold on

    colormap('colorcube');
    cmap = colormap;
    cmap = interp1(linspace(0,1,size(cmap,1)),cmap,linspace(0,1,256));

    for i = 4:5:254
        data = Frames.*(Frames == i);
        p2 = patch(isosurface(data, 0.5), 'FaceColor',cmap(i,:),'EdgeColor','none');
        isonormals(data,p2)
    end

    axis([0 sz 0 sz 1 num_frames]);
    daspect([5 5 1]);
    view(-50,30); 
    camlight;  camlight(-80,-10); 
    lighting phong; 

end
