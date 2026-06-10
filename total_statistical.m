% total_statistical.m

clc; clear; close all;

rootDir = "result";
datRoot = fullfile(rootDir, "실험 결과 dat 파일 모음");

expNames = [
    "No Agent(mod_1)"
    % "(CPU2)DDPG(Revised U1)(action 0.4%)Huber_ver1"
    % "TD3(Revised U1)(action 0.4%)Huber_ver1"
    "SAC_ver1(mod_1)"
];

labels = [
    "No Agent"
    % "DDPG"
    % "TD3"
    "SAC"
];

nexp = numel(expNames);
data = struct();

for i = 1:nexp

    data(i).label = labels(i);
    data(i).fname = expNames(i);
    data(i).dir = fullfile(datRoot, expNames(i));
    data(i).file = fullfile(data(i).dir, expNames(i) + "_all_runs.dat");

    if isfile(data(i).file)
        data(i).raw = readmatrix(data(i).file);
    else
        warning("파일이 없습니다 : %s", data(i).fname);
        data(i).raw = [];
    end
end

for i = 1:nexp

    D = data(i).raw;
    if isempty(D), continue; end

    runID = D(:,1);
    seed = D(:,2); 
    t = D(:,3);
    x = D(:,4);
    y = D(:,5);
    z = D(:,6);
    xv = D(:,7);
    yv = D(:,8);
    zv = D(:,9);
    phi = D(:,10);
    theta = D(:,11);
    psi = D(:,12);
    p = D(:,13);
    q = D(:,14);
    r = D(:,15);
    % A_Th1 = D(:,16);
    % A_Th2 = D(:,17);
    % A_Th3 = D(:,18);
    % A_Th4 = D(:,19);
    % T_Th1 = D(:,20);
    % T_Th2 = D(:,21);
    % T_Th3 = D(:,22);
    % T_Th4 = D(:,23);

    e_posh = sqrt(x.^2 + y.^2);
    e_pos3D = sqrt(x.^2 + y.^2 + z.^2);
    e_velh = sqrt(xv.^2 + yv.^2);
    e_vel3D = sqrt(xv.^2 + yv.^2 + zv.^2);
    e_attRP = sqrt(phi.^2 + theta.^2);
    e_omega = sqrt(p.^2 + q.^2 + r.^2);

    data(i).pos.x = x;
    data(i).pos.y = y;
    data(i).pos.z = z;
    data(i).angle.phi = phi;
    data(i).angle.theta = theta;
    data(i).angle.psi = psi;

    data(i).pos.x_mean = mean(x);
    data(i).pos.y_mean = mean(y);
    data(i).pos.z_mean = mean(z);
    data(i).pos.x_MAE = mean(abs(x));
    data(i).pos.y_MAE = mean(abs(y));
    data(i).pos.z_MAE = mean(abs(z));
    data(i).pos.x_RMSE = sqrt(mean(x.^2));
    data(i).pos.y_RMSE = sqrt(mean(y.^2));
    data(i).pos.z_RMSE = sqrt(mean(z.^2));
    
    data(i).vel.xv_mean = mean(xv);
    data(i).vel.yv_mean = mean(yv);
    data(i).vel.zv_mean = mean(zv);
    data(i).vel.xv_MAE = mean(abs(xv));
    data(i).vel.yv_MAE = mean(abs(yv));
    data(i).vel.zv_MAE = mean(abs(zv));
    data(i).vel.xv_RMSE = sqrt(mean(xv.^2));
    data(i).vel.yv_RMSE = sqrt(mean(yv.^2));
    data(i).vel.zv_RMSE = sqrt(mean(zv.^2));

    data(i).angle.phi_mean = mean(phi);
    data(i).angle.theta_mean = mean(theta);
    data(i).angle.psi_mean = mean(psi);
    data(i).angle.phi_MAE = mean(abs(phi));
    data(i).angle.theta_MAE = mean(abs(theta));
    data(i).angle.psi_MAE = mean(abs(psi));
    data(i).angle.phi_RMSE = sqrt(mean(phi.^2));
    data(i).angle.theta_RMSE = sqrt(mean(theta.^2));
    data(i).angle.psi_RMSE = sqrt(mean(psi.^2));

    data(i).omega.p_mean = mean(p);
    data(i).omega.q_mean = mean(q);
    data(i).omega.r_mean = mean(r);
    data(i).omega.p_MAE = mean(abs(p));
    data(i).omega.q_MAE = mean(abs(q));
    data(i).omega.r_MAE = mean(abs(r));
    data(i).omega.p_RMSE = sqrt(mean(p.^2));
    data(i).omega.q_RMSE = sqrt(mean(q.^2));
    data(i).omega.r_RMSE = sqrt(mean(r.^2));

    data(i).complex.e_posh = e_posh;
    data(i).complex.e_pos3D = e_pos3D;
    data(i).complex.e_velh = e_velh;
    data(i).complex.e_vel3D = e_vel3D;
    data(i).complex.e_attRP = e_attRP;
    data(i).complex.e_omega = e_omega;

    data(i).runID = runID;
    data(i).t = t;

    runList = unique(runID);
    nRun = numel(runList);
    
    x_RMSE_runs  = zeros(nRun,1);
    y_RMSE_runs  = zeros(nRun,1);
    z_RMSE_runs  = zeros(nRun,1);
    xv_RMSE_runs = zeros(nRun,1);
    yv_RMSE_runs = zeros(nRun,1);
    zv_RMSE_runs = zeros(nRun,1);
    phi_RMSE_runs = zeros(nRun,1);
    theta_RMSE_runs = zeros(nRun,1);
    psi_RMSE_runs = zeros(nRun,1);
    p_RMSE_runs = zeros(nRun,1);
    q_RMSE_runs = zeros(nRun,1);
    r_RMSE_runs = zeros(nRun,1);
    e_posh_RMSE_runs = zeros(nRun,1);
    e_pos3D_RMSE_runs = zeros(nRun,1);
    e_velh_RMSE_runs = zeros(nRun,1);
    e_vel3D_RMSE_runs = zeros(nRun,1);
    e_attRP_RMSE_runs = zeros(nRun,1);
    e_omega_RMSE_runs = zeros(nRun,1);
    
    for k = 1:nRun
        idxRun = (runID == runList(k));
    
        x_RMSE_runs(k)  = sqrt(mean(x(idxRun).^2,  "omitnan"));
        y_RMSE_runs(k)  = sqrt(mean(y(idxRun).^2,  "omitnan"));
        z_RMSE_runs(k)  = sqrt(mean(z(idxRun).^2,  "omitnan"));
        xv_RMSE_runs(k) = sqrt(mean(xv(idxRun).^2, "omitnan"));
        yv_RMSE_runs(k) = sqrt(mean(yv(idxRun).^2, "omitnan"));
        zv_RMSE_runs(k) = sqrt(mean(zv(idxRun).^2, "omitnan"));
        phi_RMSE_runs(k) = sqrt(mean(phi(idxRun).^2, "omitnan"));
        theta_RMSE_runs(k) = sqrt(mean(theta(idxRun).^2, "omitnan"));
        psi_RMSE_runs(k) = sqrt(mean(psi(idxRun).^2, "omitnan"));
        p_RMSE_runs(k) = sqrt(mean(p(idxRun).^2, "omitnan"));
        q_RMSE_runs(k) = sqrt(mean(q(idxRun).^2, "omitnan"));
        r_RMSE_runs(k) = sqrt(mean(r(idxRun).^2, "omitnan"));
        e_posh_RMSE_runs(k) = sqrt(mean(e_posh(idxRun).^2, "omitnan"));
        e_pos3D_RMSE_runs(k) = sqrt(mean(e_pos3D(idxRun).^2, "omitnan"));
        e_velh_RMSE_runs(k) = sqrt(mean(e_velh(idxRun).^2, "omitnan"));
        e_vel3D_RMSE_runs(k) = sqrt(mean(e_vel3D(idxRun).^2, "omitnan"));
        e_attRP_RMSE_runs(k) = sqrt(mean(e_attRP(idxRun).^2, "omitnan"));
        e_omega_RMSE_runs(k) = sqrt(mean(e_omega(idxRun).^2, "omitnan"));
        

    end
    
    data(i).pos.x_RMSE_runs  = x_RMSE_runs;
    data(i).pos.y_RMSE_runs  = y_RMSE_runs;
    data(i).pos.z_RMSE_runs  = z_RMSE_runs;
    data(i).vel.xv_RMSE_runs = xv_RMSE_runs;
    data(i).vel.yv_RMSE_runs = yv_RMSE_runs;
    data(i).vel.zv_RMSE_runs = zv_RMSE_runs;
    data(i).angle.phi_RMSE_runs  = phi_RMSE_runs;
    data(i).angle.theta_RMSE_runs  = theta_RMSE_runs;
    data(i).angle.psi_RMSE_runs  = psi_RMSE_runs;
    data(i).omega.p_RMSE_runs = p_RMSE_runs;
    data(i).omega.q_RMSE_runs = q_RMSE_runs;
    data(i).omega.r_RMSE_runs = r_RMSE_runs;
    data(i).complex.e_posh_RMSE_runs  = e_posh_RMSE_runs;
    data(i).complex.e_pos3D_RMSE_runs  = e_pos3D_RMSE_runs;
    data(i).complex.e_velh_RMSE_runs  = e_velh_RMSE_runs;
    data(i).complex.e_vel3D_RMSE_runs = e_vel3D_RMSE_runs;
    data(i).complex.e_attRP_RMSE_runs = e_attRP_RMSE_runs;
    data(i).complex.e_omega_RMSE_runs = e_omega_RMSE_runs;

end

numRun = numel(unique(data(1).runID));
tvec = unique(data(1).t);
numT = numel(tvec);

colors = [1 0 0; 0 0 1; 0 0.6 0; 0 0 0];

figure; hold on; grid on;

for i = 1:nexp
    runList = unique(data(i).runID);
    Xmat = nan(numel(runList), numT);

    for k = 1:numel(runList)
        idx = (data(i).runID == runList(k));
        t_run = data(i).t(idx);
        x_run = data(i).pos.x(idx);

        % 시간 정렬
        [t_run, order] = sort(t_run);
        x_run = x_run(order);

        % 같은 tvec를 가진다고 가정
        Xmat(k,:) = x_run(:)';
    end

    x_mean_t = mean(Xmat, 1, "omitnan");
    x_std_t  = std(Xmat, 0, 1, "omitnan");

    upper = x_mean_t + x_std_t;
    lower = x_mean_t - x_std_t;

    fill([tvec; flipud(tvec)], [upper(:); flipud(lower(:))], ...
        colors(i,:), 'EdgeColor', 'none', 'FaceAlpha', 0.15);

    plot(tvec, x_mean_t, 'Color', colors(i,:), 'LineWidth', 1.5);
end

xlabel('Time [s]');
ylabel('x [m]');
yline(0, 'r--', 'LineWidth', 2);
title('Mean ± Std of x over runs');
legend('No Agent band','No Agent', ...
       'DDPG band','DDPG', ...
       'TD3 band','TD3', ...
       'SAC band','SAC');


figure; hold on; grid on;

for i = 1:nexp
    runList = unique(data(i).runID);
    Ymat = nan(numel(runList), numT);

    for k = 1:numel(runList)
        idx = (data(i).runID == runList(k));
        t_run = data(i).t(idx);
        y_run = data(i).pos.y(idx);

        % 시간 정렬
        [t_run, order] = sort(t_run);
        y_run = y_run(order);

        % 같은 tvec를 가진다고 가정
        Ymat(k,:) = y_run(:)';
    end

    y_mean_t = mean(Ymat, 1, "omitnan");
    y_std_t  = std(Ymat, 0, 1, "omitnan");

    upper = y_mean_t + y_std_t;
    lower = y_mean_t - y_std_t;

    fill([tvec; flipud(tvec)], [upper(:); flipud(lower(:))], ...
        colors(i,:), 'EdgeColor', 'none', 'FaceAlpha', 0.15);

    plot(tvec, y_mean_t, 'Color', colors(i,:), 'LineWidth', 1.5);
end

xlabel('Time [s]');
ylabel('y [m]');
yline(0, 'r--', 'LineWidth', 2);
title('Mean ± Std of y over runs');
legend('No Agent band','No Agent', ...
       'DDPG band','DDPG', ...
       'TD3 band','TD3', ...
       'SAC band','SAC');

figure; hold on; grid on;

for i = 1:nexp
    runList = unique(data(i).runID);
    Zmat = nan(numel(runList), numT);

    for k = 1:numel(runList)
        idx = (data(i).runID == runList(k));
        t_run = data(i).t(idx);
        z_run = data(i).pos.z(idx);

        % 시간 정렬
        [t_run, order] = sort(t_run);
        z_run = z_run(order);

        % 같은 tvec를 가진다고 가정
        Zmat(k,:) = z_run(:)';
    end

    z_mean_t = mean(Zmat, 1, "omitnan");
    z_std_t  = std(Zmat, 0, 1, "omitnan");

    upper = z_mean_t + z_std_t;
    lower = z_mean_t - z_std_t;

    fill([tvec; flipud(tvec)], [upper(:); flipud(lower(:))], ...
        colors(i,:), 'EdgeColor', 'none', 'FaceAlpha', 0.15);

    plot(tvec, z_mean_t, 'Color', colors(i,:), 'LineWidth', 1.5);
end

xlabel('Time [s]');
ylabel('z [m]');
yline(0, 'r--', 'LineWidth', 2);
title('Mean ± Std of z over runs');
legend('No Agent band','No Agent', ...
       'DDPG band','DDPG', ...
       'TD3 band','TD3', ...
       'SAC band','SAC');

figure;

axesNames = ["x","y","z"];

for a = 1:3
    subplot(3,1,a);
    hold on; grid on;

    tvec = unique(data(1).t);
    numT = numel(tvec);

    for i = 1:nexp
        runList = unique(data(i).runID);
        M = nan(numel(runList), numT);

        for k = 1:numel(runList)
            idx = (data(i).runID == runList(k));

            t_run = data(i).t(idx);
            val_run = data(i).pos.(axesNames(a))(idx);

            [t_run, order] = sort(t_run);
            val_run = val_run(order);

            M(k,:) = val_run(:)';
        end

        mae_t = mean(abs(M), 1, "omitnan");
        plot(tvec, mae_t, 'LineWidth', 1.5);
    end

    legend(labels);
    xlabel("Time [s]");
    ylabel(axesNames(a) + " MAE [m]");
    title("Time-varying " + axesNames(a) + " MAE");
end

figure;

axesNames = ["x","y","z"];

for a = 1:3
    subplot(3,1,a);
    hold on; grid on;

    tvec = unique(data(1).t);
    numT = numel(tvec);

    for i = 1:nexp
        runList = unique(data(i).runID);
        M = nan(numel(runList), numT);

        for k = 1:numel(runList)
            idx = (data(i).runID == runList(k));

            t_run = data(i).t(idx);
            val_run = data(i).pos.(axesNames(a))(idx);

            [t_run, order] = sort(t_run);
            val_run = val_run(order);

            M(k,:) = val_run(:)';
        end

        rmse_t = sqrt(mean(M.^2, 1, "omitnan"));
        plot(tvec, rmse_t, 'LineWidth', 1.5);
    end

    legend(labels);
    xlabel("Time [s]");
    ylabel(axesNames(a) + " RMSE [m]");
    title("Time-varying " + axesNames(a) + " RMSE");
end

% figure;
% 
% axesNames = ["x","y","z"];
% 
% for a = 1:3
%     subplot(3,1,a);
%     hold on; grid on;
% 
%     tvec = unique(data(1).t);
%     numT = numel(tvec);
% 
%     for i = 1:nexp
%         runList = unique(data(i).runID);
%         M = nan(numel(runList), numT);
% 
%         for k = 1:numel(runList)
%             idx = (data(i).runID == runList(k));
% 
%             t_run = data(i).t(idx);
%             val_run = data(i).pos.(axesNames(a))(idx);
% 
%             [t_run, order] = sort(t_run);
%             val_run = val_run(order);
% 
%             M(k,:) = val_run(:)';
%         end
% 
%         mae_t = mean(abs(M), 1, "omitnan");
%         plot(tvec, mae_t, 'LineWidth', 1.5);
%     end
% 
%     legend(labels);
%     xlabel("Time [s]");
%     ylabel(axesNames(a) + " MAE [m]");
%     title("Time-varying " + axesNames(a) + " MAE");
% end



figure;

axesNames = ["e_pos3D","e_vel3D","e_attRP"];
units = [" [m]", " [m/s]", " [rad]"];
for a = 1:3
    subplot(3,1,a);
    hold on; grid on;

    tvec = unique(data(1).t);
    numT = numel(tvec);

    for i = 1:nexp
        runList = unique(data(i).runID);
        M = nan(numel(runList), numT);

        for k = 1:numel(runList)
            idx = (data(i).runID == runList(k));

            t_run = data(i).t(idx);
            val_run = data(i).complex.(axesNames(a))(idx);

            [t_run, order] = sort(t_run);
            val_run = val_run(order);

            M(k,:) = val_run(:)';
        end

        mae_t = mean(abs(M), 1, "omitnan");
        plot(tvec, mae_t, 'LineWidth', 1.5);
    end

    legend(labels);
    xlabel("Time [s]");
    ylabel(axesNames(a) + units(a), "Interpreter", 'none');
    title("Time-varying " + axesNames(a), "Interpreter", 'none');
end

figure;

axesNames = ["phi", "theta", "psi"];
for a = 1:3
    subplot(3,1,a);
    hold on; grid on;

    tvec = unique(data(1).t);
    numT = numel(tvec);

    for i = 1:nexp
        runList = unique(data(i).runID);
        M = nan(numel(runList), numT);

        for k = 1:numel(runList)
            idx = (data(i).runID == k);

            t_run = data(i).t(idx);
            val_run = data(i).angle.(axesNames(a))(idx);

            [t_run, order] = sort(t_run);
            val_run = val_run(order);

            M(k,:) = val_run(:)';
        end
        mae_t = mean(abs(M), 1, "omitnan");
        plot(tvec, mae_t, 'LineWidth', 1.5);
    end
    legend(labels);
    xlabel("Time [s]");
    ylabel(axesNames(a) + " MAE [rad]");
    title("Time-varying \" + axesNames(a) + " MAE");

end

figure;

axesNames = ["phi", "theta", "psi"];
for a = 1:3
    subplot(3,1,a);
    hold on; grid on;

    tvec = unique(data(1).t);
    numT = numel(tvec);

    for i = 1:nexp
        runList = unique(data(i).runID);
        M = nan(numel(runList), numT);

        for k = 1:numel(runList)
            idx = (data(i).runID == k);

            t_run = data(i).t(idx);
            val_run = data(i).angle.(axesNames(a))(idx);

            [t_run, order] = sort(t_run);
            val_run = val_run(order);

            M(k,:) = val_run(:)';
        end
        rmse_t = sqrt(mean(M.^2, 1, "omitnan"));
        plot(tvec, rmse_t, 'LineWidth', 1.5);
    end
    legend(labels);
    xlabel("Time [s]");
    ylabel(axesNames(a) + " RMSE [rad]");
    title("Time-varying \" + axesNames(a) + " RMSE");

end

% xRMSEVals = [data(1).pos.x_RMSE, data(2).pos.x_RMSE, data(3).pos.x_RMSE, data(4).pos.x_RMSE];
% yRMSEVals = [data(1).pos.y_RMSE, data(2).pos.y_RMSE, data(3).pos.y_RMSE, data(4).pos.y_RMSE];
% zRMSEVals = [data(1).pos.z_RMSE, data(2).pos.z_RMSE, data(3).pos.z_RMSE, data(4).pos.z_RMSE];
% xvRMSEVals = [data(1).vel.xv_RMSE, data(2).vel.xv_RMSE, data(3).vel.xv_RMSE, data(4).vel.xv_RMSE];
% yvRMSEVals = [data(1).vel.yv_RMSE, data(2).vel.yv_RMSE, data(3).vel.yv_RMSE, data(4).vel.yv_RMSE];
% zvRMSEVals = [data(1).vel.zv_RMSE, data(2).vel.zv_RMSE, data(3).vel.zv_RMSE, data(4).vel.zv_RMSE];
% 
% figure;
% 
% valsCell = {xRMSEVals, yRMSEVals, zRMSEVals, xvRMSEVals, yvRMSEVals, zvRMSEVals};
% names = ["x","y","z","xv","yv","zv"];
% units = [" [m]", " [m]", " [m]", " [m/s]", " [m/s]", " [m/s]"];
% barColor = [
%     1.0 0.0 0.0
%     0.0 0.0 1.0
%     0.0 0.6 0.0
%     0.0 0.0 0.0
% ];
% 
% for s = 1:6
%     subplot(2,3,s);
%     b = bar(valsCell{s}, 'FaceColor', 'flat', 'EdgeColor', 'none');
%     b.CData = barColor;
%     b.FaceAlpha = 0.5;
% 
%     grid on;
%     set(gca, 'XTickLabel', labels);
%     ylabel(names(s) + " RMSE" + units(s));
%     title("Comparison of " + names(s) + " RMSE");
% end

xRMSEMeanVals     = [mean(data(1).pos.x_RMSE_runs),     mean(data(2).pos.x_RMSE_runs),     mean(data(3).pos.x_RMSE_runs),     mean(data(4).pos.x_RMSE_runs)];
yRMSEMeanVals     = [mean(data(1).pos.y_RMSE_runs),     mean(data(2).pos.y_RMSE_runs),     mean(data(3).pos.y_RMSE_runs),     mean(data(4).pos.y_RMSE_runs)];
zRMSEMeanVals     = [mean(data(1).pos.z_RMSE_runs),     mean(data(2).pos.z_RMSE_runs),     mean(data(3).pos.z_RMSE_runs),     mean(data(4).pos.z_RMSE_runs)];
xvRMSEMeanVals    = [mean(data(1).vel.xv_RMSE_runs),    mean(data(2).vel.xv_RMSE_runs),    mean(data(3).vel.xv_RMSE_runs),    mean(data(4).vel.xv_RMSE_runs)];
yvRMSEMeanVals    = [mean(data(1).vel.yv_RMSE_runs),    mean(data(2).vel.yv_RMSE_runs),    mean(data(3).vel.yv_RMSE_runs),    mean(data(4).vel.yv_RMSE_runs)];
zvRMSEMeanVals    = [mean(data(1).vel.zv_RMSE_runs),    mean(data(2).vel.zv_RMSE_runs),    mean(data(3).vel.zv_RMSE_runs),    mean(data(4).vel.zv_RMSE_runs)];
phiRMSEMeanVals   = [mean(data(1).angle.phi_RMSE_runs), mean(data(2).angle.phi_RMSE_runs), mean(data(3).angle.phi_RMSE_runs), mean(data(4).angle.phi_RMSE_runs)];
thetaRMSEMeanVals = [mean(data(1).angle.theta_RMSE_runs), mean(data(2).angle.theta_RMSE_runs), mean(data(3).angle.theta_RMSE_runs), mean(data(4).angle.theta_RMSE_runs)];
psiRMSEMeanVals   = [mean(data(1).angle.psi_RMSE_runs), mean(data(2).angle.psi_RMSE_runs), mean(data(3).angle.psi_RMSE_runs), mean(data(4).angle.psi_RMSE_runs)];
pRMSEMeanVals     = [mean(data(1).omega.p_RMSE_runs),   mean(data(2).omega.p_RMSE_runs),   mean(data(3).omega.p_RMSE_runs),   mean(data(4).omega.p_RMSE_runs)];
qRMSEMeanVals     = [mean(data(1).omega.q_RMSE_runs),   mean(data(2).omega.q_RMSE_runs),   mean(data(3).omega.q_RMSE_runs),   mean(data(4).omega.q_RMSE_runs)];
rRMSEMeanVals     = [mean(data(1).omega.r_RMSE_runs),   mean(data(2).omega.r_RMSE_runs),   mean(data(3).omega.r_RMSE_runs),   mean(data(4).omega.r_RMSE_runs)];

xRMSEStdVals     = [std(data(1).pos.x_RMSE_runs),     std(data(2).pos.x_RMSE_runs),     std(data(3).pos.x_RMSE_runs),     std(data(4).pos.x_RMSE_runs)];
yRMSEStdVals     = [std(data(1).pos.y_RMSE_runs),     std(data(2).pos.y_RMSE_runs),     std(data(3).pos.y_RMSE_runs),     std(data(4).pos.y_RMSE_runs)];
zRMSEStdVals     = [std(data(1).pos.z_RMSE_runs),     std(data(2).pos.z_RMSE_runs),     std(data(3).pos.z_RMSE_runs),     std(data(4).pos.z_RMSE_runs)];
xvRMSEStdVals    = [std(data(1).vel.xv_RMSE_runs),    std(data(2).vel.xv_RMSE_runs),    std(data(3).vel.xv_RMSE_runs),    std(data(4).vel.xv_RMSE_runs)];
yvRMSEStdVals    = [std(data(1).vel.yv_RMSE_runs),    std(data(2).vel.yv_RMSE_runs),    std(data(3).vel.yv_RMSE_runs),    std(data(4).vel.yv_RMSE_runs)];
zvRMSEStdVals    = [std(data(1).vel.zv_RMSE_runs),    std(data(2).vel.zv_RMSE_runs),    std(data(3).vel.zv_RMSE_runs),    std(data(4).vel.zv_RMSE_runs)];
phiRMSEStdVals   = [std(data(1).angle.phi_RMSE_runs), std(data(2).angle.phi_RMSE_runs), std(data(3).angle.phi_RMSE_runs), std(data(4).angle.phi_RMSE_runs)];
thetaRMSEStdVals = [std(data(1).angle.theta_RMSE_runs), std(data(2).angle.theta_RMSE_runs), std(data(3).angle.theta_RMSE_runs), std(data(4).angle.theta_RMSE_runs)];
psiRMSEStdVals   = [std(data(1).angle.psi_RMSE_runs), std(data(2).angle.psi_RMSE_runs), std(data(3).angle.psi_RMSE_runs), std(data(4).angle.psi_RMSE_runs)];
pRMSEStdVals     = [std(data(1).omega.p_RMSE_runs),   std(data(2).omega.p_RMSE_runs),   std(data(3).omega.p_RMSE_runs),   std(data(4).omega.p_RMSE_runs)];
qRMSEStdVals     = [std(data(1).omega.q_RMSE_runs),   std(data(2).omega.q_RMSE_runs),   std(data(3).omega.q_RMSE_runs),   std(data(4).omega.q_RMSE_runs)];
rRMSEStdVals     = [std(data(1).omega.r_RMSE_runs),   std(data(2).omega.r_RMSE_runs),   std(data(3).omega.r_RMSE_runs),   std(data(4).omega.r_RMSE_runs)];

e_poshRMSEMeanVals  = [mean(data(1).complex.e_posh_RMSE_runs),  mean(data(2).complex.e_posh_RMSE_runs),  mean(data(3).complex.e_posh_RMSE_runs),  mean(data(4).complex.e_posh_RMSE_runs)];
e_pos3DRMSEMeanVals = [mean(data(1).complex.e_pos3D_RMSE_runs), mean(data(2).complex.e_pos3D_RMSE_runs), mean(data(3).complex.e_pos3D_RMSE_runs), mean(data(4).complex.e_pos3D_RMSE_runs)];
e_velhRMSEMeanVals  = [mean(data(1).complex.e_velh_RMSE_runs),  mean(data(2).complex.e_velh_RMSE_runs),  mean(data(3).complex.e_velh_RMSE_runs),  mean(data(4).complex.e_velh_RMSE_runs)];
e_vel3DRMSEMeanVals = [mean(data(1).complex.e_vel3D_RMSE_runs), mean(data(2).complex.e_vel3D_RMSE_runs), mean(data(3).complex.e_vel3D_RMSE_runs), mean(data(4).complex.e_vel3D_RMSE_runs)];
e_attRPRMSEMeanVals = [mean(data(1).complex.e_attRP_RMSE_runs), mean(data(2).complex.e_attRP_RMSE_runs), mean(data(3).complex.e_attRP_RMSE_runs), mean(data(4).complex.e_attRP_RMSE_runs)];
e_omegaRMSEMeanVals = [mean(data(1).complex.e_omega_RMSE_runs), mean(data(2).complex.e_omega_RMSE_runs), mean(data(3).complex.e_omega_RMSE_runs), mean(data(4).complex.e_omega_RMSE_runs)];

e_poshRMSEStdVals  = [std(data(1).complex.e_posh_RMSE_runs),  std(data(2).complex.e_posh_RMSE_runs),  std(data(3).complex.e_posh_RMSE_runs),  std(data(4).complex.e_posh_RMSE_runs)];
e_pos3DRMSEStdVals = [std(data(1).complex.e_pos3D_RMSE_runs), std(data(2).complex.e_pos3D_RMSE_runs), std(data(3).complex.e_pos3D_RMSE_runs), std(data(4).complex.e_pos3D_RMSE_runs)];
e_velhRMSEStdVals  = [std(data(1).complex.e_velh_RMSE_runs),  std(data(2).complex.e_velh_RMSE_runs),  std(data(3).complex.e_velh_RMSE_runs),  std(data(4).complex.e_velh_RMSE_runs)];
e_vel3DRMSEStdVals = [std(data(1).complex.e_vel3D_RMSE_runs), std(data(2).complex.e_vel3D_RMSE_runs), std(data(3).complex.e_vel3D_RMSE_runs), std(data(4).complex.e_vel3D_RMSE_runs)];
e_attRPRMSEStdVals = [std(data(1).complex.e_attRP_RMSE_runs), std(data(2).complex.e_attRP_RMSE_runs), std(data(3).complex.e_attRP_RMSE_runs), std(data(4).complex.e_attRP_RMSE_runs)];
e_omegaRMSEStdVals = [std(data(1).complex.e_omega_RMSE_runs), std(data(2).complex.e_omega_RMSE_runs), std(data(3).complex.e_omega_RMSE_runs), std(data(4).complex.e_omega_RMSE_runs)];

valsCell = {xRMSEMeanVals, yRMSEMeanVals, zRMSEMeanVals, xvRMSEMeanVals, yvRMSEMeanVals, zvRMSEMeanVals};
stdCell  = {xRMSEStdVals,  yRMSEStdVals,  zRMSEStdVals,  xvRMSEStdVals,  yvRMSEStdVals,  zvRMSEStdVals};

names = ["x","y","z","xv","yv","zv"];
units = [" [m]", " [m]", " [m]", " [m/s]", " [m/s]", " [m/s]"];

barColor = [
    1.0 0.0 0.0
    0.0 0.0 1.0
    0.0 0.6 0.0
    0.0 0.0 0.0
];

figure;

for s = 1:6
    subplot(2,3,s);
    b = bar(valsCell{s}, 'FaceColor', 'flat', 'EdgeColor', 'none');
    b.CData = barColor;
    b.FaceAlpha = 0.5;

    hold on; grid on;
    errorbar(1:4, valsCell{s}, stdCell{s}, 'k.', 'LineWidth', 1.2);

    set(gca, 'XTick', 1:4, 'XTickLabel', labels);
    ylabel(names(s) + " RMSE" + units(s), 'Interpreter', 'none');
    title("Comparison of " + names(s) + " RMSE", 'Interpreter', 'none');
end

% phiRMSEVals = [data(1).angle.phi_RMSE, data(2).angle.phi_RMSE, data(3).angle.phi_RMSE, data(4).angle.phi_RMSE];
% thetaRMSEVals = [data(1).angle.theta_RMSE, data(2).angle.theta_RMSE, data(3).angle.theta_RMSE, data(4).angle.theta_RMSE];
% psiRMSEVals = [data(1).angle.psi_RMSE, data(2).angle.psi_RMSE, data(3).angle.psi_RMSE, data(4).angle.psi_RMSE];
% pRMSEVals = [data(1).omega.p_RMSE, data(2).omega.p_RMSE, data(3).omega.p_RMSE, data(4).omega.p_RMSE];
% qRMSEVals = [data(1).omega.q_RMSE, data(2).omega.q_RMSE, data(3).omega.q_RMSE, data(4).omega.q_RMSE];
% rRMSEVals = [data(1).omega.r_RMSE, data(2).omega.r_RMSE, data(3).omega.r_RMSE, data(4).omega.r_RMSE];
% 
% figure;
% 
% valsCell = {phiRMSEVals, thetaRMSEVals, psiRMSEVals, pRMSEVals, qRMSEVals, rRMSEVals};
% names = ["phi","theta","psi","p","q","r"];
% units = [" [rad]", " [rad]", " [rad]", " [rad/s]", " [rad/s]", " [rad/s]"];
% barColor = [
%     1.0 0.0 0.0
%     0.0 0.0 1.0
%     0.0 0.6 0.0
%     0.0 0.0 0.0
% ];
% 
% for s = 1:6
%     subplot(2,3,s);
%     b = bar(valsCell{s}, 'FaceColor', 'flat', 'EdgeColor', 'none');
%     b.CData = barColor;
%     b.FaceAlpha = 0.5;
% 
%     grid on;
%     set(gca, 'XTickLabel', labels);
%     ylabel(names(s) + " RMSE" + units(s));
%     title("Comparison of " + names(s) + " RMSE");
% end
% 
% e_poshVals  = [mean(data(1).complex.e_posh),  mean(data(2).complex.e_posh),  mean(data(3).complex.e_posh),  mean(data(4).complex.e_posh)];
% e_pos3DVals = [mean(data(1).complex.e_pos3D), mean(data(2).complex.e_pos3D), mean(data(3).complex.e_pos3D), mean(data(4).complex.e_pos3D)];
% e_velhVals  = [mean(data(1).complex.e_velh),  mean(data(2).complex.e_velh),  mean(data(3).complex.e_velh),  mean(data(4).complex.e_velh)];
% e_vel3DVals = [mean(data(1).complex.e_vel3D), mean(data(2).complex.e_vel3D), mean(data(3).complex.e_vel3D), mean(data(4).complex.e_vel3D)];
% e_attRPVals = [mean(data(1).complex.e_attRP), mean(data(2).complex.e_attRP), mean(data(3).complex.e_attRP), mean(data(4).complex.e_attRP)];
% e_omegaVals = [mean(data(1).complex.e_omega), mean(data(2).complex.e_omega), mean(data(3).complex.e_omega), mean(data(4).complex.e_omega)];
% 
% figure;
% 
% valsCell = {e_poshVals, e_pos3DVals, e_velhVals, e_vel3DVals, e_attRPVals, e_omegaVals};
% names = ["e_posh","e_pos3D","e_velh","e_vel3D","e_attRP","e_omega"];
% units = [" [m]"," [m]", " [m/s]", " [m/s]", " [rad]", " [rad]"];
% 
% barColor = [
%     1.0 0.0 0.0
%     0.0 0.0 1.0
%     0.0 0.6 0.0
%     0.0 0.0 0.0
% ];
% 
% for s = 1:6
%     subplot(2,3,s);
%     b = bar(valsCell{s}, 'FaceColor', 'flat', 'EdgeColor', 'none');
%     b.CData = barColor;
%     b.FaceAlpha = 0.5;
% 
%     grid on;
%     set(gca, 'XTickLabel', labels);
%     ylabel(names(s) + units(s), 'Interpreter', 'none');
%     title("Comparison of " + names(s), 'Interpreter', 'none');
% end

%% =========================================================
%% Remaining 6 state RMSE bar plots with error bars
%% (phi, theta, psi, p, q, r)
%% =========================================================
valsCell = {phiRMSEMeanVals, thetaRMSEMeanVals, psiRMSEMeanVals, ...
            pRMSEMeanVals, qRMSEMeanVals, rRMSEMeanVals};

stdCell  = {phiRMSEStdVals, thetaRMSEStdVals, psiRMSEStdVals, ...
            pRMSEStdVals, qRMSEStdVals, rRMSEStdVals};

names = ["phi","theta","psi","p","q","r"];
units = [" [rad]"," [rad]"," [rad]"," [rad/s]"," [rad/s]"," [rad/s]"];

barColor = [
    1.0 0.0 0.0
    0.0 0.0 1.0
    0.0 0.6 0.0
    0.0 0.0 0.0
];

figure;
for s = 1:6
    subplot(2,3,s);
    b = bar(valsCell{s}, 'FaceColor', 'flat', 'EdgeColor', 'none');
    b.CData = barColor;
    b.FaceAlpha = 0.5;

    hold on; grid on;
    errorbar(1:4, valsCell{s}, stdCell{s}, 'k.', 'LineWidth', 1.2);

    set(gca, 'XTick', 1:4, 'XTickLabel', labels);
    ylabel(names(s) + " RMSE" + units(s), 'Interpreter', 'none');
    title("Comparison of " + names(s) + " RMSE", 'Interpreter', 'none');
end
sgtitle('RMSE Comparison of Attitude and Angular Rate', 'Interpreter', 'none');


%% =========================================================
%% Complex RMSE bar plots with error bars
%% =========================================================
valsCell = {e_poshRMSEMeanVals, e_pos3DRMSEMeanVals, e_velhRMSEMeanVals, ...
            e_vel3DRMSEMeanVals, e_attRPRMSEMeanVals, e_omegaRMSEMeanVals};

stdCell  = {e_poshRMSEStdVals, e_pos3DRMSEStdVals, e_velhRMSEStdVals, ...
            e_vel3DRMSEStdVals, e_attRPRMSEStdVals, e_omegaRMSEStdVals};

names = ["e_posh","e_pos3D","e_velh","e_vel3D","e_attRP","e_omega"];

figure;
for s = 1:6
    subplot(2,3,s);
    b = bar(valsCell{s}, 'FaceColor', 'flat', 'EdgeColor', 'none');
    b.CData = barColor;
    b.FaceAlpha = 0.5;

    hold on; grid on;
    errorbar(1:4, valsCell{s}, stdCell{s}, 'k.', 'LineWidth', 1.2);

    set(gca, 'XTick', 1:4, 'XTickLabel', labels);
    ylabel(names(s) + " RMSE", 'Interpreter', 'none');
    title("Comparison of " + names(s) + " RMSE", 'Interpreter', 'none');
end
sgtitle('RMSE Comparison of Complex Metrics', 'Interpreter', 'none');


%% =========================================================
%% Plane projection scatter plots (1 out of every 10 samples)
%% =========================================================
sampleStep = 100;

plotColors = [
    1.0 0.0 0.0   % No Agent
    0.0 0.0 1.0   % DDPG
    0.0 0.6 0.0   % TD3
    0.0 0.0 0.0   % SAC
];

markerSize = 15;

% ---------- 1) x-y plane ----------
figure;
hold on; grid on;

for i = 1:nexp
    x_all = data(i).pos.x;
    y_all = data(i).pos.y;

    idxSample = 1:sampleStep:numel(x_all);

    scatter(x_all(idxSample), y_all(idxSample), ...
        markerSize, ...
        'MarkerEdgeColor', plotColors(i,:), ...
        'DisplayName', labels(i));
end

xlabel("x");
ylabel("y");
xline(0, 'r--', 'LineWidth', 1.5); yline(0, 'r--', 'LineWidth', 1.5); 
title("x-y plane projection", 'Interpreter', 'none');
legend('Interpreter','none', 'Location','best');
axis equal;

% ---------- 2) x-z plane ----------
figure;
hold on; grid on;

for i = 1:nexp
    x_all = data(i).pos.x;
    z_all = data(i).pos.z;

    idxSample = 1:sampleStep:numel(x_all);

    scatter(x_all(idxSample), z_all(idxSample), ...
        markerSize, ...
        'MarkerEdgeColor', plotColors(i,:), ...
        'DisplayName', labels(i));
end

xlabel("x");
ylabel("z");
xline(0, 'r--', 'LineWidth', 1.5); yline(0, 'r--', 'LineWidth', 1.5); 
title("x-z plane projection", 'Interpreter', 'none');
legend('Interpreter','none', 'Location','best');
axis equal;

% ---------- 3) y-z plane ----------
figure;
hold on; grid on;

for i = 1:nexp
    y_all = data(i).pos.y;
    z_all = data(i).pos.z;

    idxSample = 1:sampleStep:numel(y_all);

    scatter(y_all(idxSample), z_all(idxSample), ...
        markerSize, ...
        'MarkerEdgeColor', plotColors(i,:), ...
        'DisplayName', labels(i));
end

xlabel("y");
ylabel("z");
xline(0, 'r--', 'LineWidth', 1.5); yline(0, 'r--', 'LineWidth', 1.5); 
title("y-z plane projection", 'Interpreter', 'none');
legend('Interpreter','none', 'Location','best');
axis equal;

