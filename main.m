clc, clear, close all

%%% functions
num_tag = 2; % how many tags in the scene
skip = 0; 
display = 1; %% show numerical results
verification_flag = 1;
correspondance_per_pose = 4;
method = "4 points";


%%% parameters for optimization
num_alternative_opt = 4; % how many rounds of alternative optimization (4)
num_LiDARTag_pose = 5; % how many LiDARTag poses to optimize H_LC (5) (2)
num_scan = 3; % how many scans accumulated to optimize one  LiDARTag pose (3)

opt.rpy_init = [45 2 3];
opt.T_init = [2, 0, 0];
opt.H_init = eye(4);
opt.method = "Constraint Customize"; %% will add more later on
opt.UseCentroid = 1;

%%% training and validation
num_training = 1; %%% 2
num_verification = 7; % use how many different data to verify the calibration result

%%% target size
% big 
params.tag_size_biggest = 0.8051;
params.target_len_biggest = 0.8051;

% small
params.tag_size_small = 0.158;
params.target_len_small = 0.158;

% meduim
params.tag_size_medium = 0.225;
params.target_len_medium = 0.225;

%%% bag selection (training and validation)              
bag_with_tag_list  = ["3Tags-OldLiDAR.bag", "lab2-closer.bag", "lab_angled.bag" ...
             "lab3-closer-cleaner.bag", "lab4-closer-cleaner.bag", "lab5-closer-cleaner.bag", ...
             "lab6-closer-cleaner.bag", "lab7-closer-cleaner.bag", "lab8-closer-cleaner.bag", ...
             "wavefield3-tag.bag", "wavefield5-tag.bag"];
         
skip_indices = [1, 2, 3];
num_verification = min(size(bag_with_tag_list, 2)- length(skip_indices) - num_training, num_verification);

bag_testing_list = ["EECS3.bag", "verification2-45.bag", "verification3-45.bag", ...
    "grove2.bag", "verification5-45.bag", "outdoor6-notag.bag", "outdoor4.bag", "outdoor5.bag"];

test_pc_mat_list = ["velodyne_points-EECS3--2019-09-06-06-19.mat", "velodyne_points-verification2--2019-09-03-23-02.mat",...
    "velodyne_points-verification3--2019-09-03-23-03.mat", "velodyne_points-grove2--2019-09-06-06-20.mat",...
    "velodyne_points-verification5--2019-09-03-23-03.mat", "velodyne_points-outdoor6-NoTag--2019-09-06-10-31.mat", ...
    "velodyne_points-outdoor4--2019-09-04-18-16.mat", "velodyne_points-outdoor5--2019-09-04-18-20.mat"];

%%% file parmeters
% load_dir = "Paper-C71/21-Sep-2019 00:15:59/";
% load_dir = "../Paper-C71/14-Sep-2019 12:49:13-testing/";

bag_file_path = "bagfiles/";
mat_file_path = "LiDARTag_data/";

training_img_fig_handles = createFigHandle(num_training, "training_img");
training_pc_fig_handles = createFigHandle(num_training, "training_pc");

verfication_fig_handles = createFigHandle(num_verification, "validation_img");
verfication_pc_fig_handles = createFigHandle(num_verification, "validation_pc");

testing_fig_handles = createFigHandle(size(bag_testing_list, 2), "testing");

%%% camera parameters
intrinsic_matrix = [616.3681640625, 0.0, 319.93463134765625;
                        0.0, 616.7451171875, 243.6385955810547;
                    0.0, 0.0, 1.0];
distortion_param = [0.099769, -0.240277, 0.002463, 0.000497, 0.000000];

BagData = getBagData();           

%
% get training indices
bag_training_indices = randi([4, length(bag_with_tag_list)], 1, num_training);

% make sure they are not the same and not consists of undesire index
while length(unique(bag_training_indices)) ~=  length(bag_training_indices) || ...
        any(ismember(bag_training_indices, skip_indices)) 
    bag_training_indices = randi([4, length(bag_with_tag_list)], 1, num_training);
end

 % overwrite
bag_training_indices = 11;
training_bag = bag_with_tag_list(bag_training_indices);

% get validation indices
bag_verification_indices = randi(length(bag_with_tag_list), 1, num_verification);
% make sure they are not the same and not consists of undesire index
while length(unique(bag_verification_indices)) ~=  length(bag_verification_indices) || ...
      any(ismember(bag_verification_indices, skip_indices)) || ...
      any(ismember(bag_verification_indices, bag_training_indices)) 
   bag_verification_indices = randi(length(bag_with_tag_list), 1, num_verification);
end
bag_verification_indices = [4 5 6 7 8 9 10];
bag_chosen_indices = [bag_training_indices, bag_verification_indices];

% overwrite
%              bag_chosen_indices = [bag_training_indices, 8];

c = datestr(datetime);          
save_name = "Paper-C71";
diary Paper-C71-diary
available_indices = [4 5 6 7 8 9 10 11];
count = 0;
ans_error_big_matrix = [];
ans_counting_big_matrix = [];


if skip
    load(load_dir + 'saved_chosen_indices.mat');
    load(load_dir + 'saved_parameters.mat');
    num_alternative_opt = 4;
end

disp("********************************************")
disp(" Chosen dataset")
disp("********************************************")
disp("-- Skipped: ")
disp(bag_with_tag_list(skip_indices))
disp("-- Training set: ")
disp(bag_with_tag_list(bag_training_indices))            
disp("-- Validation set: ")
disp([bag_with_tag_list(bag_verification_indices)])
disp("-- Chosen set: ")
disp(bag_with_tag_list(bag_chosen_indices))

disp("********************************************")
disp(" Chosen parameters")
disp("********************************************")
fprintf("-- %i tag(s) in the scene\n", num_tag)
fprintf("-- verfication flag: %i \n", verification_flag)
fprintf("-- number of training set: %i\n", size(bag_training_indices, 2))
fprintf("-- number of verfication set: %i\n", size(bag_verification_indices, 2))
fprintf("-- number of refinement: %i\n", num_alternative_opt)
fprintf("-- number of LiDARTag's poses: %i\n", num_LiDARTag_pose)
fprintf("-- number of total LiDARTag's poses: %i\n", size(bag_training_indices, 2) * num_LiDARTag_pose * num_tag)
fprintf("-- number of scan to optimize a LiDARTag pose: %i\n", num_scan)
c = datetime;
c = datestr(c);
save_dir = save_name + "/" + c + "/";



if ~skip
    mkdir(save_dir);
    save(save_dir + 'saved_parameters.mat', 'num_verification', 'num_scan', 'num_training','num_tag', 'num_alternative_opt', 'num_LiDARTag_pose', 'verification_flag', 'num_verification');
    save(save_dir + 'saved_chosen_indices.mat', 'skip_indices', 'bag_training_indices', 'bag_verification_indices', 'bag_chosen_indices');
end



% loadBagImg(training_fig_handles(1), bag_file_path + bag_list(1), 0);


index = find(strcmp(bag_with_tag_list, training_bag(1)));
% bag_pre = app.bagfile;
% app.bagfile = bag_file_path + bag_list(index);
% pc_iter_pre = app.pc_iter;
% full_scan_pre = app.full_pointcloud_name;
% app.full_pointcloud_name = BagData(index).full_scan;
%             showImage(app);
%             
% loading training image
for i = 1:num_training
    current_index = bag_training_indices(i);
    loadBagImg(training_img_fig_handles(i), bag_file_path + bag_with_tag_list(current_index), "not display", "not clean");
end

% for i = 1:num_training
%     current_index = bag_training_indices(i);
%     loadBagImg(training_pc_fig_handles(i), bag_file_path + test_pc_mat_list(current_index), "not display", "not clean");
% end


for i = 1:num_verification
    current_index = bag_verification_indices(i);
    loadBagImg(verfication_fig_handles(i), bag_file_path + bag_with_tag_list(current_index), "not display", "not clean");
end

% load testing images
for i = 1: size(bag_testing_list, 2)
    loadBagImg(testing_fig_handles(i), bag_file_path + bag_testing_list(i), "not display", "not clean"); 
end

% load testing pc mat
testing_set_pc = loadTestingMatFiles(mat_file_path, test_pc_mat_list);


%
if skip == 1 || skip == 2
    load(load_dir + "X_base_line.mat");
    load(load_dir + "X_train.mat");
    load(load_dir + "Y.mat")
    load(load_dir + "save_verification.mat")
else
    X_train = []; % LiDARTag corners in 3D
    Y_train = []; % AprilTag corners in 2D
    X_verification = []; % LiDARTag corners in 3D
    Y_verification = []; % AprilTag corners in 2D
    H_LT_big = [];
    X_base_line_edge_points = [];
    X_base_line = [];
    Y_base_line = [];
    N_base_line = [];
    disp("********************************************")
    disp(" Optimizing LiDARTag poses")
    disp("********************************************")
    for i = 1:num_LiDARTag_pose
        if num_tag == 1
            %%% big
            image_num = i;
            app.pc_iter = num_scan*(i-1) + 1;

            [LiDARTag_large, AprilTag_large] = get4Corners(app, BagData(index).name_biggest, apriltag_txt_biggest, bag_with_tag_list(index), tag_size_biggest, target_len_biggest, image_num, num_scan);
            AprilTag_large.four_corners_line =  point2DToLineForDrawing(app, AprilTag_large.corners.large);
            showLinedLiDARTag(app, LiDARTag_large);
            showLinedAprilTag(app, app.AprilTagFig, AprilTag_large.corners.large, AprilTag_large.four_corners_line);
            % 1 tag
            X_train = [X_train, LiDARTag_large.corners]; % 4 x M*i, M is correspondance per scan, i is scan
            Y_train = [Y_train, AprilTag_large.corners.large]; % 3 x M*i, M is correspondance per image, i is image

        elseif num_tag == 2
            %%% small
            fprintf("--- Working on scan: %i/%i\n", i, num_LiDARTag_pose)
            verification_counter = 1;
            for k = 1:length(bag_chosen_indices)
                current_index = bag_chosen_indices(k);
                fprintf("Working on %s -->", bag_with_tag_list(current_index))

                % skip undesire index
                if any(ismember(current_index, skip_indices))
                    continue
                end

                % if don't want to get verification set, skip
                % everything else but the traing set
                if ~verification_flag
                    if ~any(ismember(bag_training_indices, current_index))
                        continue;
                    end
                end

                % training set
                if any(ismember(bag_training_indices, current_index))
                    image_num = i;
                    pc_iter = num_scan*(i-1) + 1; 
                    [LiDARTag_small, AprilTag_small, small_H_LT] = get4CornersReturnHLT(opt, mat_file_path, BagData(current_index).name_small, ...
                        BagData(current_index).bagfile, params.target_len_small, pc_iter, num_scan);
    %                             [LiDARTag_small, AprilTag_small] = get4Corners(app, BagData(current_index).name_small, apriltag_txt_small, ...
    %                                                                     bag_list(current_index), tag_size_small, target_len_small, image_num, num_scan);
                    AprilTag_small.four_corners_line =  point2DToLineForDrawing(AprilTag_small.corners.small);
                    showLinedLiDARTag(training_pc_fig_handles(k), LiDARTag_small, "display");
                    showLinedAprilTag(training_img_fig_handles(k), AprilTag_small.corners.small, AprilTag_small.four_corners_line, "display");
                    training_scan(i).dataset(k).payload_small = LiDARTag_small.points;
                    %%% big
                    image_num = i;
                    pc_iter = num_scan*(i-1) + 1;
                    [LiDARTag_large, AprilTag_large, large_H_LT] = get4CornersReturnHLT(opt, mat_file_path, BagData(current_index).name_biggest, ...
                                                            BagData(current_index).bagfile, params.tag_size_biggest, pc_iter, num_scan);
                    training_scan(i).dataset(k).payload_big = LiDARTag_large.points;
    %                             [LiDARTag_large, AprilTag_large] = get4Corners(app, BagData(current_index).name_biggest, apriltag_txt_biggest,...
    %                                 bag_list(current_index), tag_size_biggest, target_len_biggest, image_num, num_scan);
                    AprilTag_large.four_corners_line =  point2DToLineForDrawing(AprilTag_large.corners.large);
                    showLinedLiDARTag(training_pc_fig_handles(k), LiDARTag_large, "display");
                    showLinedAprilTag(training_img_fig_handles(k), AprilTag_large.corners.large, AprilTag_large.four_corners_line, "display");
                    drawnow

                    % 2tags
                    X_train = [X_train, LiDARTag_small.corners,       LiDARTag_large.corners]; % 4 x M*i, M is correspondance per scan, i is scan
                    Y_train = [Y_train, AprilTag_small.corners.small, AprilTag_large.corners.large]; % 3 x M*i, M is correspondance per image, i is image
                    fprintf(" Got training set: %s\n", bag_with_tag_list(current_index))

                    %%% [corners, normal_vector]=
    %                             [corners_big, edges] = KaessNewCorners(app, BagData(current_index).name_biggest);
                    pc_iter = num_scan*(i-1) + 1;
                    [corners_big, edges]= KaessNewConstraintCorners(mat_file_path, BagData(current_index).name_biggest, pc_iter);
    %                             figure(4);
    %                             scatter3(cross_big_3d(1,:), cross_big_3d(2,:), cross_big_3d(3,:))
    %                             [corners_small, small_normal_vec] = KaessCorners(app, BagData(index).name_small);
    %                             X_base_line = [X_base_line, corners_small, corners_big];
    %                             Y_base_line = [Y_base_line, AprilTag_small.corners.small, AprilTag_large.corners.large];
    %                             N_base_line = [N_base_line, small_normal_vec];
                    X_base_line = [X_base_line, corners_big];
                    Y_base_line = [Y_base_line, AprilTag_large.corners.large];
                    X_base_line_edge_points = [X_base_line_edge_points, edges];
                    H_LT_big = [H_LT_big, small_H_LT, large_H_LT];

                else
                    %%% verification set
                    if verification_counter > num_verification
                        break;
                    end
                    image_num = i;
                    pc_iter = num_scan*(i-1) + 1;

                    [verificatoin_LiDARTag_small, verificatoin_AprilTag_small, ~] = get4CornersReturnHLT(opt, mat_file_path, BagData(current_index).name_small, ...
                                                                                        BagData(current_index).bagfile, params.target_len_small, pc_iter, num_scan);
                    verificatoin_AprilTag_small.four_corners_line =  point2DToLineForDrawing(verificatoin_AprilTag_small.corners.small);
                    showLinedLiDARTag(verfication_pc_fig_handles(k-num_training), verificatoin_LiDARTag_small, "display");
                    showLinedAprilTag(verfication_fig_handles(k-num_training), verificatoin_AprilTag_small.corners.small, verificatoin_AprilTag_small.four_corners_line, "display");
                    verification_scan(i).dataset(verification_counter).payload_small = verificatoin_LiDARTag_small.points;

                    %%% big
                    image_num = i;
                    pc_iter = num_scan*(i-1) + 1;


                    [verificatoin_LiDARTag_large, verificatoin_AprilTag_large, ~] = get4CornersReturnHLT( opt, mat_file_path, BagData(current_index).name_biggest, ...
                                                                BagData(current_index).bagfile, params.target_len_biggest, pc_iter, num_scan);
                    verification_scan(i).dataset(verification_counter).payload_big = verificatoin_LiDARTag_large.points;
                    verificatoin_AprilTag_large.four_corners_line =  point2DToLineForDrawing(verificatoin_AprilTag_large.corners.large);
                    showLinedLiDARTag(verfication_pc_fig_handles(k-num_training), verificatoin_LiDARTag_large, "display");
                    showLinedAprilTag(verfication_fig_handles(k-num_training), verificatoin_AprilTag_large.corners.large, verificatoin_AprilTag_large.four_corners_line, "display");

                    %%% 2tags
                    X_verification = [X_verification, verificatoin_LiDARTag_small.corners,       verificatoin_LiDARTag_large.corners]; % 4 x M*i, M is correspondance per scan, i is scan
                    Y_verification = [Y_verification, verificatoin_AprilTag_small.corners.small, verificatoin_AprilTag_large.corners.large]; % 3 x M*i, M is correspondance per image, i is image
                    fprintf(" Got verificatoin set: %s\n", bag_with_tag_list(current_index))
                    verification_counter = verification_counter + 1;
                end

            end

        elseif num_tag == 3
            %%% smallest
            image_num = i;
            app.pc_iter = num_scan*(i-1) + 1;
            [LiDARTag_small, AprilTag_small] = get4Corners(app, name_small, apriltag_txt_small, bag_with_tag_list(current_index), tag_size_small, target_len_small, image_num, num_scan);
            AprilTag_small.four_corners_line =  point2DToLineForDrawing(app, AprilTag_small.corners.small);
            showLinedLiDARTag(app, LiDARTag_small);
            showLinedAprilTag(app, app.AprilTagFig, AprilTag_small.corners.small, AprilTag_small.four_corners_line);


            %%% middle
            image_num = i;
             app.pc_iter = num_scan*(i-1) + 1;
            [LiDARTag_medium, AprilTag_medium] = get4Corners(app, name_medium, apriltag_txt_medium, bag_with_tag_list(current_index), tag_size_medium, target_len_medium, image_num, num_scan);
            AprilTag_medium.four_corners_line =  point2DToLineForDrawing(app, AprilTag_medium.corners.medium);
            showLinedLiDARTag(app, LiDARTag_medium);
            showLinedAprilTag(app, app.AprilTagFig, AprilTag_medium.corners.medium, AprilTag_medium.four_corners_line)

            %%% big
            image_num = i;
            app.pc_iter = num_scan*(i-1) + 1;
            [LiDARTag_large, AprilTag_large] = get4Corners(app, name_biggest, apriltag_txt_biggest, bag_with_tag_list(current_index), tag_size_biggest, target_len_biggest, image_num, num_scan);
            AprilTag_large.four_corners_line =  point2DToLineForDrawing(app, AprilTag_large.corners.large);
            showLinedLiDARTag(app, LiDARTag_large);
            showLinedAprilTag(app, app.AprilTagFig, AprilTag_large.corners.large, AprilTag_large.four_corners_line);
            % 3 tags
            X_train = [X_train, LiDARTag_small.corners,       LiDARTag_medium.corners,        LiDARTag_large.corners]; % 4 x M*i, M is correspondance per scan, i is scan
            Y_train = [Y_train, AprilTag_small.corners.small, AprilTag_medium.corners.medium, AprilTag_large.corners.large]; % 3 x M*i, M is correspondance per image, i is image

        end
    %                 Y = [Y, AprilTag_small.undistorted_corners.small, AprilTag_large.undistorted_corners.large];
        fprintf("--- Finished scan: %i\n", i)
    end
    drawnow
    save(save_dir + 'X_base_line.mat', 'X_base_line');
    save(save_dir + 'X_train.mat', 'X_train', 'H_LT_big', 'X_base_line_edge_points', 'training_scan');
    save(save_dir + 'Y.mat', 'Y_train', 'Y_base_line');
    save(save_dir + 'save_verification.mat', 'X_verification', 'Y_verification', 'verification_scan');
end

%
if ~(skip == 2)
    X_square_no_refinement = X_train;
    X_not_square_refinement = X_base_line;
    disp("********************************************")
    disp(" Calibrating...")
    disp("********************************************")



    %             ave_dH_SR_vec = zeros(1,6);
    %             ave_dH_NSR_vec = zeros(1,6);

    %%% tweak
    %             H_tweak = eye(4);
    %             H_tweak(1:3,1:3) = rotx(2) * roty(40) * rotz(-3);
    %             X_train = H_tweak * X_train;
    switch method
        case 'matlab'
            cameraParams = cameraParameters('IntrinsicMatrix', intrinsic_matrix');
            [worldOrientation,worldLocation] = estimateWorldCameraPose(Y_train(1:2,:)', X_train(1:3, :)', cameraParams);
            H_LC = eye(4);
            H_LC(1:3, 1:3) = worldOrientation;
            H_LC(4, 1:3) = worldLocation;
            H_LC = H_LC';
            app.P = app.intrinsic_matrix * [eye(3) zeros(3,1)] * H_LC;

        case "4 points"
             % one shot calibration (*-NR)
            [SNR_H_LC, SNR_P, SNR_opt_total_cost] = optimize4Points(X_square_no_refinement, Y_train, intrinsic_matrix, display); % square withOUT refinement
            [NSNR_H_LC, NSNR_P, NSNR_opt_total_cost] = optimize4Points(X_base_line, Y_base_line, intrinsic_matrix, display); % NOT square withOUT refinement

            if num_alternative_opt > 0
                for i = 1: num_alternative_opt
                    disp('---------------------')
                    disp(' Optimizing H_LC ...')
                    disp('---------------------')

                    [SR_H_LC, SR_P, SR_opt_total_cost] = optimize4Points(X_train, Y_train, intrinsic_matrix, display); % square with refinement
                    [NSR_H_LC, NSR_P, NSR_opt_total_cost] = optimize4Points(X_not_square_refinement, Y_base_line, intrinsic_matrix, display); % NOT square with refinement
                    
                    if i == num_alternative_opt
                        break;
                    else
                        disp('------------------')
                        disp(' Refining H_LT ...')
                        disp('------------------')
                        X_train = regulizedFineTuneLiDARTagPose(params, X_train, Y_train, H_LT_big, SR_P, correspondance_per_pose, display);
                        X_not_square_refinement = regulizedFineTuneKaessCorners(X_not_square_refinement, Y_base_line, ...
                                        X_base_line_edge_points, NSR_P, correspondance_per_pose, display);

                    end
                end
            else
    %                         disp('---------------------')
    %                         disp(' Optimizing H_LC ...')
    %                         disp('---------------------')
                [app.H_LC, app.P, app.opt_total_cost] = optimize4Points(X_train, Y_train, intrinsic_matrix, display);
            end

        case "IoU"
            % one shot calibration (*-NR)
            [SNR_H_LC, SNR_P, SNR_opt_total_cost] = optimize4Points(X_square_no_refinement, Y_train, intrinsic_matrix, display); % square withOUT refinement
            [NSNR_H_LC, NSNR_P, NSNR_opt_total_cost] = optimize4Points(X_base_line, Y_base_line, intrinsic_matrix, display); % NOT square withOUT refinement

            if Alternating
                for i = 1: num_alternative_opt
                    disp('---------------------')
                    disp(' Optimizing H_LC ...')
                    disp('---------------------')

                    [SR_H_LC, SR_P, SR_opt_total_cost] = optimizeIoU(X_train, Y_train, intrinsic_matrix); % square with refinement
                    [NSR_H_LC, NSR_P, NSR_opt_total_cost] = optimizeIoU(X_not_square_refinement, Y_base_line, intrinsic_matrix); % NOT square with refinement
                    if i == num_alternative_opt
                        break;
                    else
                        disp('------------------')
                        disp(' Refining H_LT ...')
                        disp('------------------')

                        X_train = regulizedFineTuneLiDARTagPose(params, X_train, Y_train, H_LT_big, SR_P, ...
                                                                correspondance_per_pose, display);
                        X_not_square_refinement = regulizedFineTuneKaessCorners(X_not_square_refinement, ...
                                                                Y_base_line, X_base_line_edge_points, NSR_P, ...
                                                                correspondance_per_pose, display);
                    end
                end
            end
        case "Customize"
    end
%             save(save_dir + 'X_base_line.mat', 'X_base_line');
%             save(save_dir + 'X_not_square_refinement.mat', 'X_not_square_refinement');
%             save(save_dir + 'X_square_no_refinement.mat', 'X_square_no_refinement');
%             save(save_dir + 'X_train.mat', 'X_train');
%             save(save_dir + 'Y.mat', 'Y_train', 'Y_base_line');
%             
%             save(save_dir + 'save_verification.mat', 'X_verification', 'Y_verification');
%             save(save_dir + 'NSNR.mat', 'NSNR_H_LC', 'NSNR_P', 'NSNR_opt_total_cost');
%             save(save_dir + 'SNR.mat', 'SNR_H_LC', 'SNR_P', 'SNR_opt_total_cost');
%             save(save_dir + 'NSR.mat', 'NSR_H_LC', 'NSR_P', 'NSR_opt_total_cost');
%             save(save_dir + 'SR.mat',  'SR_H_LC', 'SR_P', 'SR_opt_total_cost');
end
%
if skip
%                 load(load_dir + "X_base_line.mat");
%                 load(load_dir + "X_not_square_refinement.mat");
%                 load(load_dir + "X_square_no_refinement.mat");
%                 load(load_dir + "X_train.mat");
%                 load(load_dir + "Y.mat")

%                 load(load_dir + "NSNR.mat");
%                 load(load_dir + "SNR.mat");
%                 load(load_dir + "NSR.mat");
%                 load(load_dir + "SR.mat");
%                 load(load_dir + "save_verification.mat")
end
if num_alternative_opt > 0
    app.H_LC = SR_H_LC;
    app.P = SR_P;
    app.opt_total_cost = SR_opt_total_cost;
end

%             dH_LT_SR = eye(4);
%             dH_LT_SR(1:3,1:3) = expm(skew(app, ave_dH_SR_vec(1:3)));
%             dH_LT_SR(1:3,4) = ave_dH_SR_vec(4:6)';
%             
%             dH_LT_NSR = eye(4);
%             dH_LT_NSR(1:3,1:3) = expm(skew(app, ave_dH_NSR_vec(1:3)));
%             dH_LT_NSR(1:3,4) = ave_dH_NSR_vec(4:6)';
%             

if verification_flag
    SR_verification_cost = verifyCornerAccuracyWRTDataset(num_verification, num_LiDARTag_pose, num_tag, ...
            X_verification, Y_verification, SR_P);
    NSR_verification_cost = verifyCornerAccuracyWRTDataset(num_verification, num_LiDARTag_pose, num_tag, ...
            X_verification, Y_verification, NSR_P);
    SNR_verification_cost = verifyCornerAccuracyWRTDataset(num_verification, num_LiDARTag_pose, num_tag, ...
            X_verification, Y_verification, SNR_P);



    NSNR_verification_cost = verifyCornerAccuracyWRTDataset(num_verification, num_LiDARTag_pose, num_tag, ...
        X_verification, Y_verification, NSNR_P);
    [t_SNR_count, t_SR_count] = inAndOutBeforeAndAfter(training_scan, Y_train, SNR_P, SR_P, num_training, num_LiDARTag_pose, num_tag);
    [t_NSNR_count, t_NSR_count] = inAndOutBeforeAndAfter(training_scan, Y_train, NSNR_P, NSR_P, num_training, num_LiDARTag_pose, num_tag);

    [SNR_count, SR_count] = inAndOutBeforeAndAfter(verification_scan, Y_verification, SNR_P, SR_P, num_verification, num_LiDARTag_pose, num_tag);
    [NSNR_count, NSR_count] = inAndOutBeforeAndAfter(verification_scan, Y_verification, NSNR_P, NSR_P, num_verification, num_LiDARTag_pose, num_tag);
%                 SR_verification_cost = verifyCornerAccuracy(app, X_verification, Y_verification, SR_P);
%                 SNR_verification_cost = verifyCornerAccuracy(app, X_verification, Y_verification, SNR_P);
%                 NSR_verification_cost = verifyCornerAccuracy(app, X_verification, Y_verification, NSR_P);
%                 NSNR_verification_cost = verifyCornerAccuracy(app, X_verification, Y_verification, NSNR_P);
end

%             drawRotated2Dpoint(app, app.AprilTagFig, NSNR_H_LC, X_base_line);
%kaess_H_LC = kaess_H_LC * normal_vector
disp("****************** NSNR-training ******************")
disp('NSNR_H_LC: ')
disp(' R:')
disp(NSNR_H_LC(1:3, 1:3))
disp(' RPY (XYZ):')
disp(rad2deg(rotm2eul(NSNR_H_LC(1:3, 1:3), "XYZ")))
disp(' T:')
disp(-inv(NSNR_H_LC(1:3, 1:3))*NSNR_H_LC(1:3, 4))
disp("========= Error =========")
disp(' Training Total Error (pixel)')
disp(NSNR_opt_total_cost)
disp(' Training Error Per Corner (pixel)')
disp(NSNR_opt_total_cost/size(Y_base_line, 2)) % 2 tags, 4 corners
ans_error_submatrix = [bag_training_indices(1); NSNR_opt_total_cost/size(Y_base_line, 2)];
disp("****************** NSR-training ******************")
disp('NSR_H_LC: ')
disp(' R:')
disp(NSR_H_LC(1:3, 1:3))
disp(' RPY (XYZ):')
disp(rad2deg(rotm2eul(NSR_H_LC(1:3, 1:3), "XYZ")))
disp(' T:')
disp(-inv(NSR_H_LC(1:3, 1:3))*NSR_H_LC(1:3, 4))
disp("========= Error =========")
disp(' Training Total Error (pixel)')
disp(NSR_opt_total_cost)
disp(' Training Error Per Corner (pixel)')
disp(NSR_opt_total_cost/size(Y_base_line, 2)) % 2 tags, 4 corners
ans_error_submatrix = [ans_error_submatrix; NSR_opt_total_cost/size(Y_base_line, 2)];
disp("****************** SNR-training ******************")
disp('SNR_H_LC: ')
disp(' R:')
disp(SNR_H_LC(1:3, 1:3))
disp(' RPY (XYZ):')
disp(rad2deg(rotm2eul(SNR_H_LC(1:3, 1:3), "XYZ")))
disp(' T:')
disp(-inv(SNR_H_LC(1:3, 1:3))*SNR_H_LC(1:3, 4))
disp("========= Error =========")
disp(' Training Total Error (pixel)')
disp(SNR_opt_total_cost)
disp(' Training Error Per Corner (pixel)')
disp(SNR_opt_total_cost/size(Y_train, 2)) % 2 tags, 4 corners
ans_error_submatrix = [ans_error_submatrix; SNR_opt_total_cost/size(Y_base_line, 2)];
disp("****************** SR-training ******************")
disp('H_LC: ')
disp(' R:')
disp(app.H_LC(1:3, 1:3))
disp(' RPY (XYZ):')
disp(rad2deg(rotm2eul(app.H_LC(1:3, 1:3), "XYZ")))
disp(' T:')
disp(-inv(app.H_LC(1:3, 1:3))*app.H_LC(1:3, 4))
disp("========= Error =========")
disp(' Training Total Error (pixel)')
disp(app.opt_total_cost)
disp(' Training Error Per Corner (pixel)')
disp(app.opt_total_cost/size(Y_train, 2)) % 2 tags, 4 corners
ans_error_submatrix = [ans_error_submatrix; app.opt_total_cost/size(Y_base_line, 2)];
ans_error_big_matrix = [ans_error_submatrix];

if length(bag_training_indices)>1
    for i = 2:length(bag_training_indices)
        index = bag_training_indices(i);
        ans_error_submatrix(1) = index;
        ans_error_big_matrix = [ans_error_big_matrix, ans_error_submatrix];
    end
end

if verification_flag
    disp("***************** Verification Error*****************")
    for i = 1:num_verification
        disp('------')
        current_index = bag_verification_indices(i);
        fprintf("---dataset: %s\n", bag_with_tag_list(current_index))
        ans_error_submatrix = [bag_verification_indices(i)];
        disp("-- Error Per Corner (pixel)")
        disp(' NSNR Verification Error Per Corner (pixel)')
        disp(NSNR_verification_cost(i).total_cost/ size(Y_verification, 2))
        ans_error_submatrix = [ans_error_submatrix; SNR_opt_total_cost/size(Y_base_line, 2)];
        disp(' NSR Verification Error Per Corner (pixel)')
        disp(NSR_verification_cost(i).total_cost/ size(Y_verification, 2))
        ans_error_submatrix = [ans_error_submatrix; SNR_opt_total_cost/size(Y_base_line, 2)];
        disp(' SNR Verification Error Per Corner (pixel)')
        disp(SNR_verification_cost(i).total_cost/ size(Y_verification, 2))
        ans_error_submatrix = [ans_error_submatrix; SNR_opt_total_cost/size(Y_base_line, 2)];
        disp(' SR Verification Error Per Corner (pixel)')
        disp(SR_verification_cost(i).total_cost/ size(Y_verification, 2))
        ans_error_submatrix = [ans_error_submatrix; SNR_opt_total_cost/size(Y_base_line, 2)];
        ans_error_big_matrix = [ans_error_big_matrix, ans_error_submatrix];
%                     disp("-- STD of error of small and big tag (pixel)")
%                     disp(' NSNR Verification STD of Error (pixel)')
%                     disp(NSNR_verification_cost(i).mix_std)
%                     disp(' NSR Verification STD of Error (pixel)')
%                     disp(NSR_verification_cost(i).mix_std)
%                     disp(' SNR Verification STD of Error (pixel)')
%                     disp(SNR_verification_cost(i).mix_std)
%                     disp(' SR Verification STD of Error (pixel)')
%                     disp(SR_verification_cost(i).mix_std)
%                     disp('------')
    end

disp("***************** Training point counting *****************")
disp("project full pc (SR)")
disp([t_SR_count])
disp("project full pc (SNR)")
disp([t_SNR_count])
disp("project full pc (NSR)")
disp([t_NSR_count])
disp("project full pc (NSNR)")
disp([t_NSNR_count])
disp("diff")
disp(([t_NSR_count] - [t_NSNR_count])./[t_NSNR_count])
disp(([t_SR_count] - [t_SNR_count])./[t_SNR_count])
for i = 1:length(bag_training_indices)
    ans_subcount_matrix = [bag_training_indices(i); t_NSNR_count(i); t_NSR_count(i); t_SNR_count(i); t_SR_count(i)]; 
    ans_counting_big_matrix = [ans_counting_big_matrix, ans_subcount_matrix];
end

disp("***************** Verification point counting *****************")

disp("project full pc (SR)")
disp([SR_count])
disp("project full pc (SNR)")
disp([SNR_count])
disp("project full pc (NSR)")
disp([NSR_count])
disp("project full pc (NSNR)")
disp([NSNR_count])
disp("diff")
disp(([NSR_count] - [NSNR_count])./[NSNR_count])
disp(([SR_count] - [SNR_count])./[SNR_count])

end
for i = 1:length(bag_verification_indices)
    ans_subcount_matrix = [bag_verification_indices(i); NSNR_count(i); NSR_count(i); SNR_count(i); SR_count(i)]; 
    ans_counting_big_matrix = [ans_counting_big_matrix, ans_subcount_matrix];
end

%             disp("========= std =========")
%             [mean_training, std_training] = computeSTD(app, X_train, num_training, num_LiDARTag_pose, num_tag);
%             [mean_verification, std_verification] = computeSTD(app, X_verification, num_verification, num_LiDARTag_pose, num_tag);
%             disp(' std of training set')
%             disp(std_verification)
%             disp(' std of verfication set')
%             disp(std_training)
%             
%             disp("========= mean =========")
%             disp(' mean of training set')
%             disp(mean_verification)
%             disp(mean_training)
%             disp(' mean of verfication set')
%             disp(mean_training)
%             diff(std(diff(X_verification')))
disp("********************************************")

if ~verification_flag
    save(save_dir + 'verfication_cost' , 'SR_verification_cost', 'SNR_verification_cost', 'NSR_verification_cost', 'NSNR_verification_cost');

end

%         end
%     end

%     save(save_dir + 'result.mat','ans_counting_big_matrix', 'ans_error_big_matrix');
% end

%%% CAD model
%             cad_H_LC = eye(4);
%             cad_R_LC = rotx(90) * rotz(90);
%             cad_T_LC = [0.1, 0.03, -0.2]';
%             cad_H_LC(1:3,:) = [cad_R_LC -cad_R_LC*cad_T_LC];
%             app.P = app.intrinsic_matrix * [eye(3) zeros(3,1)] * cad_H_LC;

%%% disturbance 
%             disturb_H_LC = eye(4);
%             disturb_R_LC = rotx(84) * rotz(90);
%             disturb_T_LC = [0.1268 0.0315 -0.1996]';
%             disturb_H_LC(1:3,:) = [disturb_R_LC -disturb_R_LC*disturb_T_LC];
%             app.P = app.intrinsic_matrix * [eye(3) zeros(3,1)] * disturb_H_LC;

%%% Wil's 
%             Will_H_LC = eye(4);
%             Will_R_LC = [-0.0087 -1.0000 0.0012;
%                           0.0194   -0.0013   -0.9998;
%                           0.9998   -0.0087    0.0194];
%             Will_T_LC = [0.0913 -0.0024 -0.0918]';
%             Will_H_LC(1:3,:) = [Will_R_LC -Will_R_LC*Will_T_LC];
%             app.P = app.intrinsic_matrix * [eye(3) zeros(3,1)] * Will_H_LC;

%%% showing results

%             training_corners_NSNR = splitData(app, X_base_line, num_training, num_LiDARTag_pose, 1);
%             training_corners_SNR = splitData(app, X_square_no_refinement, num_training, num_LiDARTag_pose, num_tag);
%             training_corners_NSR = splitData(app, X_not_square_refinement, num_training, num_LiDARTag_pose, 1);
%             training_corners_SR = splitData(app, X_train, num_training, num_LiDARTag_pose, num_tag);
%             scan_NSNR = splitData(app, X_base_line, num_training, num_LiDARTag_pose, 1);
%             scan_SNR = splitData(app, X_square_no_refinement, num_training, num_LiDARTag_pose, num_tag);
%             scan_NSR = splitData(app, X_not_square_refinement, num_training, num_LiDARTag_pose, 1);
%             scan_SR = splitData(app, X_train, num_training, num_LiDARTag_pose, num_tag);
%             
%             for j = 1:num_LiDARTag_pose
%                 for i = 1:num_training  
%                     current_corners_SNR = [scan(j).training_corners_SNR(i).corner(:).corner];
%                     current_corners_SNR = [scan_SNR(j).dataset(i).corner(:).corner];
%                     prjectBackToImage(app, training_fig_handles(i), SNR_P, current_corners_SNR, 'm*', "training_SNR");
%                     
%                     current_corners_NSR = [scan(j).training_corners_NSR(i).corner(:).corner];
%                     current_corners_NSR = [scan_NSR(j).dataset(i).corner(:).corner];
%                     prjectBackToImage(app, training_fig_handles(i), NSR_P, current_corners_NSR, 'c*', "training_NSR");
%                     
%                     current_corners_NSNR = [scan(j).training_corners_NSNR(i).corner(:).corner];
%                     current_corners_NSNR = [scan_NSNR(j).dataset(i).corner(:).corner];
%                     prjectBackToImage(app, training_fig_handles(i), NSNR_P, current_corners_NSNR, 'b*', "training_NSNR");
%                     
%                     current_corners_SR = [scan(j).training_corners_SR(i).corner(:).corner];
%                     current_corners_SR = [scan_SR(j).dataset(i).corner(:).corner];
%                     prjectBackToImage(app, training_fig_handles(i), SR_P, current_corners_SR, 'g*', "training_SR");
%                     drawnow
%                 end
%              end
%             
%             if verification_flag
%                 verification_scan = splitData(app, X_verification, num_verification, num_LiDARTag_pose, num_tag);
%                 for i = 1:num_verification
%                     for j = 1:num_LiDARTag_pose
%                         current_corners = [verification_scan(j).dataset(i).corner(:).corner];
%                         prjectBackToImage(app, verfication_fig_handles(i), SNR_P, current_corners, 'm*', "Verification_SNR");
%                         prjectBackToImage(app, verfication_fig_handles(i), NSR_P, current_corners, 'c*', "Verification_NSR");
%                         prjectBackToImage(app, verfication_fig_handles(i), NSNR_P, current_corners, 'b*', "Verification_NSNR");
%                         prjectBackToImage(app, verfication_fig_handles(i), SR_P, current_corners, 'g*', "Verification_SR");
%                     end
%                 end
%             end
%                         training_corners_NSNR = splitData(app, X_base_line, num_training, num_LiDARTag_pose, 1);
%             training_corners_SNR = splitData(app, X_square_no_refinement, num_training, num_LiDARTag_pose, num_tag);
%             training_corners_NSR = splitData(app, X_not_square_refinement, num_training, num_LiDARTag_pose, 1);
%             training_corners_SR = splitData(app, X_train, num_training, num_LiDARTag_pose, num_tag);
scan_NSNR = splitData(X_base_line, num_training, num_LiDARTag_pose, 1);
scan_SNR = splitData(X_square_no_refinement, num_training, num_LiDARTag_pose, num_tag);
scan_NSR = splitData(X_not_square_refinement, num_training, num_LiDARTag_pose, 1);
scan_SR = splitData(X_train, num_training, num_LiDARTag_pose, num_tag);

for j = 1:num_LiDARTag_pose
    for i = 1:num_training  
%                     current_corners_SNR = [scan_SNR(j).dataset(i).corner(:).corner];
%                     prjectBackToImage(app, training_fig_handles(i), SNR_P, current_corners_SNR, 'm*', "training_SNR");
%                     
%                     current_corners_NSR = [scan_NSR(j).dataset(i).corner(:).corner];
%                     prjectBackToImage(app, training_fig_handles(i), NSR_P, current_corners_NSR, 'c*', "training_NSR");
%                     
%                     current_corners_NSNR = [scan_NSNR(j).dataset(i).corner(:).corner];
%                     prjectBackToImage(app, training_fig_handles(i), NSNR_P, current_corners_NSNR, 'b*', "training_NSNR");

        current_corners_SR = [scan_SR(j).dataset(i).corner(:).corner];
        prjectBackToImage(training_img_fig_handles(i), SR_P, current_corners_SR, 5, 'g*', "training_SR", "not display", "Not-Clean");
        drawnow
    end
 end

if verification_flag
    verification_scan_corner = splitData(X_verification, num_verification, num_LiDARTag_pose, num_tag);
    for i = 1:num_verification
        for j = 1:num_LiDARTag_pose
            current_corners = [verification_scan_corner(j).dataset(i).corner(:).corner];
            
            if size(verification_scan(j).dataset(i).payload_big, 1) ~= 4
                current_payload_big = [verification_scan(j).dataset(i).payload_big; 
                                       ones(1, size(verification_scan(j).dataset(i).payload_big, 2))];
            else
                current_payload_big = verification_scan(j).dataset(i).payload_big;
            end
            
            if size(verification_scan(j).dataset(i).payload_small, 1) ~= 4
                current_payload_small = [verification_scan(j).dataset(i).payload_small;
                                         ones(1, size(verification_scan(j).dataset(i).payload_small, 2))];
            else
                current_payload_small = verification_scan(j).dataset(i).payload_small;
            end
            
            prjectBackToImage(verfication_fig_handles(i), SR_P, current_corners, 5, 'g*', "Verification_SR", "display", "Not-Clean");
            prjectBackToImage(verfication_fig_handles(i), SR_P, current_payload_big, 5, 'r.', "Verification_SR", "not display", "Not-Clean");
            prjectBackToImage(verfication_fig_handles(i), SR_P, current_payload_small, 5, 'r.', "Verification_SR", "not display", "Not-Clean");
%             
%             prjectBackToImage(verfication_fig_handles(i), SR_P, verification_scan(j).dataset(i).payload_big, 5, 'r.', "Verification_SR", "display", "Not-Clean");
%             prjectBackToImage(verfication_fig_handles(i), SR_P, verification_scan(j).dataset(i).payload_small, 5, 'r.', "Verification_SR", "display", "Not-Clean");
            
        end
    end
end

%%% draw results
% %             prjectBackToImage(app, app.P, X_train);
for i = 1:size(test_pc_mat_list, 2)
     prjectBackToImage(testing_fig_handles(i), SR_P, testing_set_pc(i).mat_pc, 3, 'g.', "testing", "display", "Not-Clean")
end
disp("********************************************")
disp("Projected.")
disp("********************************************")

SR_P





         