%Main_SIFT3D
addpath('C:\Program Files\SIFT3D 1.4.5\lib\sift3d\wrappers\matlab');

fprintf('RUN this code on MATLAB2015');
pn_def = 'C:\Users\gengoro\SynologyDrive\AI\Tad\Select\crop2_sel\Rot0.48\movie_package';
pn_input = uigetdir(pn_def,'select AVI folder');
sift3d_batch(pn_input);
rmpath('C:\Program Files\SIFT3D 1.4.5\lib\sift3d\wrappers\matlab');

%fprintf('RUN this code on MATLAB2015 or newer');
%select_FP([pn_input '\SIFT3D']);