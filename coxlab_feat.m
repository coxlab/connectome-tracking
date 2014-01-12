systemCommand = ['python slmsimple_args.py ', 'isbi_merged/pngs/train-input-norm-00.png'];
[status, result] = system(systemCommand);
disp(status);
disp(result);
load('fmap.mat');
effmap = dispfm(fmap, 1024);
figure; imshow(effmap, []);
