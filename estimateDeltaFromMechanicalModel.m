function [delta, opt, valid_targets]= estimateDeltaFromMechanicalModel(opt, data, plane, delta, num_beams, num_targets)
    tic;
    valid_targets(num_beams).skip = [];
    valid_targets(num_beams).valid = [];
    valid_targets(num_beams).num_points = [];
    for ring = 1:num_beams
        valid_targets(ring) = checkRingsCrossDataset(data, num_targets, ring);
        if ~valid_targets(ring).skip
    %         ring
    %         dbstop in estimateDelta.m at 13 if ring>=32
    %         D_corr = -0.01;
    %         theta_corr = 0;
    %         phi_corr = 0;
    %         cost = optimizeMultiIntrinsicCost(data, plane, ring, D_corr, theta_corr, phi_corr)

    %         theta_x = optimvar('theta_x', 1, 1,'LowerBound',-2,'UpperBound',2); % 1x1
    %         theta_y = optimvar('theta_y', 1, 1,'LowerBound',-2,'UpperBound',2); % 1x1
    %         theta_z = optimvar('theta_z', 1, 1,'LowerBound',-2,'UpperBound',2); % 1x1
    %         T = optimvar('T', 1, 3, 'LowerBound',[-0.05 -0.05 -0.05],'UpperBound',[0.05 0.05 0.05]); % 1x3
            D_corr = optimvar('D_corr', 1, 1,'LowerBound',-0.5,'UpperBound',0.5); % 1x1
            theta_corr = optimvar('theta_corr', 1, 1,'LowerBound',deg2rad(-2),'UpperBound',deg2rad(2)); % 1x1
            phi_corr = optimvar('phi_corr', 1, 1,'LowerBound',deg2rad(-2),'UpperBound',deg2rad(2)); % 1x1

            prob = optimproblem;
            f = fcn2optimexpr(@optimizeMultiIntrinsicCostSpherical, data,  valid_targets(ring), plane, ring,...
                               D_corr, theta_corr, phi_corr);
            prob.Objective = f;
            x0.D_corr = opt.D_corr_init;
            x0.theta_corr = opt.theta_corr_init;
            x0.phi_corr = opt.phi_corr_init;
    %         x0.T = opt.T_init;

            % 'Display','iter'
            options = optimoptions('fmincon', 'MaxIter',5e2, 'Display','off', 'TolX', 1e-6, 'TolFun', 1e-6, 'MaxFunctionEvaluations', 3e4);
            max_trail = 5;
            num_tried = 1;
            status = 0;
            while status <=0 
                [sol, fval, status, ~] = solve(prob, x0, 'Options', options);
                if status <=0 
                    warning("optimization failed")
                end
                num_tried = num_tried + 1;
                if (num_tried + 1 > max_trail)
                    warning("tried too many time, optimization still failed, current status:")
                    disp(status)
                    break;
                end
            end
    %         R_final = rotx(sol.theta_x) * roty(sol.theta_y) * rotz(sol.theta_z);
    %         delta(ring).H = eye(4);
    %         delta(ring).H(1:3, 1:3) = R_final;
    %         delta(ring).H(1:3, 4) = sol.T;
            delta(ring).D = sol.D_corr;
            delta(ring).theta = sol.theta_corr;
            delta(ring).phi = sol.phi_corr;
            delta(ring).opt_total_cost = fval;
            opt.computation_time(ring).time = toc;
        else
            delta(ring).D = 0;
            delta(ring).theta = 0;
            delta(ring).phi = 0;
            delta(ring).opt_total_cost = 0;
        end
    end
end