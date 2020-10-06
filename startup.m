saved_path = path();
save('./.app/saved_path.mat', 'saved_path');
clear saved_path
addpath(genpath('data'));
addpath(genpath('src'));
addpath(genpath('.app'));