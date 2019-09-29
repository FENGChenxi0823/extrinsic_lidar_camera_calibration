clear; clc;

% Single variable called point_cloud
data = load('LiDARTag_data/velodyne_points-verification3--2019-09-03-23-03.mat');
[scans, points_per_scan, values] = size(data.point_cloud);

%% Step 1: Calculate the d, theta, phi from the x, y, z of point  cloud
% d     - length of beam
% theta - azimuth angle off of x axis
% phi   - elevation angle
xs = data.point_cloud(:,:,1);
ys = data.point_cloud(:,:,2);
zs = data.point_cloud(:,:,3);

d     = sqrt(xs.^2 + ys.^2 + zs.^2);
phi   = atan2(zs ./ sqrt(xs.^2 + ys.^2));
theta = atan2(ys ./ xs);

%% Step 2: Calculate 'ground truth' points by projecting the angle onto the
% normal plane
%
% Assumption: we have the normal plane at this step in the form:
% plane_normal = [nx ny nz]

% example normal lies directly on the x axis
plane_normal = [5, 0, 0]; % arbitrary at the moment

magnitude_plane_normal = norm(plane_normal, 2);

angles = zeros(scans, points_per_scan, 3);
angles(:,:,1) = xs ./ d;
angles(:,:,2) = ys ./ d;
angles(:,:,3) = zs ./ d;

normals = zeros(scans, points_per_scan, 3);
normals(:,:,1) = plane_normal(1)*ones(scans, points_per_scan);
normals(:,:,2) = plane_normal(2)*ones(scans, points_per_scan);
normals(:,:,3) = plane_normal(3)*ones(scans, points_per_scan);

numerator = magnitude_plane_normal.^2;
denominator = dot(normals, angles, 3);
d_hat = numerator ./ denominator;

% d_hat now holds the projection of a point P onto the plane normal

%% Step 3: Find the delta_d to minimize the projection error
% This delta_d represents the range offset in the LiDAR






