function effmap = coxlab_feat(file, size)
% COXLAB_FEAT Produces a full Cox lab feature map for an image.
%   effmap = coxlab_feat(file, size)

%   Inputs:
%       file - Path to image file
%       imsize - Desired size length (for cropping)
%   Outputs:
%       effmap - Full feature map

systemCommand = ['python slmsimple_args.py ', file, ' ', num2str(size)];
[status, result] = system(systemCommand);

if (~status)
    load('fmap.mat'); % slmsimple_args.py
    effmap = fullfm(fmap, size);

    % crop and normalize 
    % TODO: do not hardcode the artifact size to crop
    effmap = effmap(1:size-7, 1:size-7, :);
    effmap = uint8(mat2gray(effmap)*255);
else
    disp(result);
    error('seg:CLfeatgen', 'CoxLab feature generation failure.'); 
end
    
end
