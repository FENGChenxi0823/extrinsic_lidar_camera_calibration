clear; clc;
num_beams = 32; % config of lidar
 
% Single variable called point_cloud
path = "/home/chenxif/Documents/me590/Calibration/IntrinsicCalibration/extracted_tags/";
mat_file_path = {path+'velodyne_points-Intrinsic-LargeTag--2019-11-21-22-04.mat',...
                 path+'velodyne_points-Intrinsic-SmallTag--2019-11-21-22-00.mat',...
                 path+'velodyne_points-Intrinsic4-SmallTag--2019-11-22-22-54.mat',...
                 path+'velodyne_points-Intrinsic5-LargeTag--2019-11-22-23-02.mat',...
                 path+'velodyne_points-Intrinsic5-SmallTag--2019-11-22-23-00.mat',...
                 path+'velodyne_points-Intrinsic-further-LargeTag--2019-11-22-23-05.mat',...
                 path+'velodyne_points-Intrinsic-further-SmallTag--2019-11-22-23-09.mat',...
                 path+'velodyne_points-Intrinsic-further2-LargeTag--2019-11-22-23-15.mat',...
                 path+'velodyne_points-Intrinsic-further2-SmallTag--2019-11-22-23-17.mat',...
                 path+'velodyne_points-upper1-SmallTag--2019-12-05-20-13.mat',...
                 path+'velodyne_points-upper2-SmallTag--2019-12-05-20-16.mat',...
                 path+'velodyne_points-upper3-SmallTag--2019-12-05-20-19.mat',...
                 path+'velodyne_points-upper4-SmallTag--2019-12-05-20-22.mat',...
                 path+'velodyne_points-upper5-SmallTag--2019-12-05-20-23.mat',...
                 path+'velodyne_points-upper6-SmallTag--2019-12-05-20-26.mat',...
                 path+'velodyne_points-upper7-SmallTag--2019-12-05-20-29.mat',...
                 path+'velodyne_points-upper8-SmallTag--2019-12-05-20-29.mat'};

num_targets = length(mat_file_path);
pc = cell(1,num_targets);
for t = 1:num_targets
    pc{t} = loadPointCloud(mat_file_path{t});
end
num_scans = 1;
delta(num_beams).D = struct();
delta(num_beams).theta = struct();
delta(num_beams).phi = struct();
%%
for i = 1: num_scans
    scans = 1;
    data = cell(1,num_targets);% XYZIR 
    for t = 1:num_targets
        data{t} = getPayload(pc{t}, i , 1);
    end
    % Step 2: Calculate 'ground truth' points by projecting the angle onto the
    % normal plane
    %
    % Assumption: we have the normal plane at this step in the form:
    % plane_normal = [nx ny nz]

    % example normal lies directly on the x axis
    opt.corners.rpy_init = [45 2 3];
    opt.corners.T_init = [2, 0, 0];
    opt.corners.H_init = eye(4);
    opt.corners.method = "Constraint Customize"; %% will add more later on
    opt.corners.UseCentroid = 1;
    
    plane = cell(1,num_targets);
    spherical_data = cell(1,num_targets);
    data_split_with_ring = cell(1,num_targets);
    data_split_with_ring_raw = cell(1,num_targets);
    for t = 1:num_targets
        [plane{t}, ~] = estimateNormal(opt.corners, data{t}(1:3, :), 0.8051);
        spherical_data{t} = Cartesian2Spherical(data{t});
        data_split_with_ring{t} = splitPointsBasedOnRing(spherical_data{t}, num_beams);
        data_split_with_ring_raw{t} = splitPointsBasedOnRing(data{t}, num_beams);
    end
    
    opt.delta.D_corr_init = 0;
    opt.delta.theta_corr_init = 0;
    opt.delta.phi_corr_init = 0;
    delta = estimateDelta(opt.delta, data_split_with_ring, plane, delta(num_beams), num_beams, num_targets);
end
disp('done')