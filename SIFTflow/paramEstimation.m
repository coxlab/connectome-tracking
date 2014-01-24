% Params: training image, corresp. ground truth image, low thresh.,
%   high thresh., xi1 parameter close to 1, mu1 > 0, mu2 > 0
%   **notes: training image pixel values need to be [0,255]
function [t1_new, t2_new, reliable1, reliable2] = paramEstimation(im, gt, t1, t2, xi1, mu1, mu2)
    steps = 0;
    max_steps = 50;
    t1_new = 0; t2_new = 0;
    
    while (steps < max_steps || (t1_new - t1 < 0.5 && t2_new - t2 < 0.5))
        steps = steps + 1;
        disp(steps);
        reliable1 = true;
        reliable2 = true;
        xi2 = 1 - xi1;

        tmap1 = tmap(im, gt, t1)
        tmap2 = tmap(im, gt, t2)

        % check reliability
        if tmap1 < xi1
            reliable1 = false;
            if t2 - t1 < 2
                t2 = t2 + 1;
            else
                t1 = t1 + 1;
            end
        end

        if tmap2 > xi2
            reliable2 = false;
            if t2 - t1 < 2
                t1 = t1 - 1;
            else
                t2 = t2 - 1;
            end
        end

        % update
        t1_new = t1 + mu1*tmap1;
        t2_new = t2 + mu2*tmap2; 
    end

end



function ratio = tmap(im, gt, x)
    % numerator is num. target pixels (background pixels?) that have feature value x
    TargetIdx = find(gt == 0);
    numer = sum(arrayfun(@(j) im(j) == x, TargetIdx));
    
    % denominator is num. pixels total that have feature value x 
    denom =  length(find(im == x));
    
    ratio =  numer/denom;
end



function h = heaviside2(x)
    if x > 0
        h = 1;
    else
        h = 0;
    end
end

function g = discrim(im, gt, x, i)
    % gamma1 is target, gamma2 is background

    % P(x|gamma1) is the prob. that a target pixel has this intensity
    TargetIdx = find(gt > 0);
    px1 = sum(arrayfun(@(j) im(j) == x, TargetIdx))/length(TargetIdx);
    
    % P(x|gamma2) is the prob. that a background pixel has this intensity
    BgIdx = find(gt == 0);
    px2 = sum(arrayfun(@(j) im(j) == x, BgIdx))/length(BgIdx);
    
    % P(gamma1|i) = gt(i) is the prob. that a pixel at this loc is target (0
    % or 1?)
    
    g = px1 - gt(i)*(px1 + px2);
end