function effmap = dispfm(ftmap, network, imsize)

effmap = zeros(imsize);
effcnt = zeros(imsize);
effrng = calfpsize(network, size(network,2), 1) - 1;

for y=1:size(ftmap,1)
for x=1:size(ftmap,2)
    effloc = [1 1] + ([y x]-[1 1])*(2.^(size(network,2)-1));
    
    effmap(effloc(1):effloc(1)+effrng, effloc(2):effloc(2)+effrng) = ...
    effmap(effloc(1):effloc(1)+effrng, effloc(2):effloc(2)+effrng) + ftmap(y, x);

    effcnt(effloc(1):effloc(1)+effrng, effloc(2):effloc(2)+effrng) = ...
    effcnt(effloc(1):effloc(1)+effrng, effloc(2):effloc(2)+effrng) + 1;
end
end

effcnt(effcnt(:)==0) = 1;
effmap = effmap ./ effcnt;

if (nargout == 0)
    imagesc(effmap); drawnow;
end

%%%%%%%%%%

function footprint = calfpsize(network, Lmax, lastnorm)

footprint = 1;

for l = Lmax:-1:1
    % Normalize
    if (network{l}.norm.size ~= 0)
        if ((l~=Lmax) || (lastnorm==1))
            footprint = footprint + network{l}.norm.size - 1;
        end
    end
    
    % Pool
    if (network{l}.pool.size ~= 0)
        footprint = (footprint-1)*network{l}.pool.stride + network{l}.pool.size;
    end
    
    % Filter
    if (network{l}.filt.size ~= 0)
        footprint = footprint + network{l}.filt.size - 1;
    end
end