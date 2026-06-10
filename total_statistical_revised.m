%total_statistical_revised.m
%=========기준 버전들==========
% "No Agent (mod_ 1)"
% % "(DDPG)Reward_Gain_ver1(action 1%)(mod_1)"
% "(TD3)Reward_Gain_ver1(action 1%)(mod_1)"
% "(bias0.001)Reward_Gain_ver2(Scaled)(action 1%)(mod_1)"


clc; clear; close all;

rootDir = "result";
datRoot = fullfile(rootDir, "실험 결과 dat 파일 모음");

expNames = [
    % "No Agent (mod_ 1)"
    % "(DDPG)Reward_Gain_ver1(action 1%)(mod_1)"
    % "(TD3)Reward_Gain_ver1(action 1%)(mod_1)"
    % "(bias0.001)Reward_Gain_ver2(Scaled)(action 1%)(mod_1)"

    %"No Agent(mod_1)"
    % "(0.02)DDPG_ver4(mod_1)"
    % "(0.02)TD3_ver3(mod_1)"
    %"(0.02)SAC_ver15(mod_1)"

    % "No Agent(mod_2)"

    % "(ScaledL1)(0.02)DDPG_ver1(mod_1)"
    % "(L2)(0.02)DDPG_ver1(mod_1)"
    % "(0.02)DDPG_ver4(mod_1)"

    % "(ScaledL1)(0.02)TD3_ver1(mod_1)"
    % "(L2)(0.02)TD3_ver1(mod_1)"
    % "(0.02)TD3_ver3(mod_1)"

    % "(ScaledL1)(0.02)SAC_ver1(mod_1)"
    % "(L2)(0.02)SAC_ver1(mod_1)"
    % "(0.02)SAC_ver15(mod_1)"

    "No Agent(mod_1)"
    "(Huber)(0.02)DDPG_ver1(mod_1)"
    "(Revised)TD3_ver1(mod_1)"
    "(cpu2)(Huber)(0.02)SAC_ver4(mod_1)"

    % "No Agent(mod_1)"
    % "(cpu2)(ScaledL1)(0.02)SAC_ver1(mod_1)"
    % "(cpu3)(L2)(0.02)SAC_ver1(mod_1)"
    % "(cpu1)(Huber)(0.02)SAC_ver4(mod_1)"
];

labels = [
    "No Agent"
    "DDPG"
    "TD3"
    "SAC"
    
    % "No Agent"
    % "Scaled L1"
    % "L2"
    % "Huber"

    % "DDPG(L1)"
    % "DDPG(L2)"
    % "DDPG(huber)"

    % "TD3(L1)"
    % "TD3(L2)"
    % "TD3(huber)"

    % "SAC(L1)"
    % "SAC(L2)"
    % "SAC"

];

nexp = numel(expNames);
D = struct();

for i = 1:nexp

    file = fullfile(datRoot, expNames(i), expNames(i) + "_all_runs.dat");

    if ~isfile(file)
        warning("파일이 없습니다: %s", file);
        continue;
    end

    M = readmatrix(file);

    D(i).label = labels(i);
    D(i).fname = expNames(i);

    caseList = unique(M(:,2));
    
    for c = 1:numel(caseList)
        caseNum = caseList(c);
        idxCase = (M(:,2) == caseNum);
        M_case = M(idxCase, :);

        runList = unique(M_case(:,1));

        for r = 1:numel(runList)
            runNum = runList(r);
            idxRun = (M_case(:,1) == runNum);
            R = M_case(idxRun, :);

            D(i).case(caseNum).run(runNum).t       = R(:,3);
            D(i).case(caseNum).run(runNum).x       = R(:,4);
            D(i).case(caseNum).run(runNum).y       = R(:,5);
            D(i).case(caseNum).run(runNum).z       = R(:,6);
            D(i).case(caseNum).run(runNum).e_v_dir = R(:,7);
            D(i).case(caseNum).run(runNum).e_v_mag = R(:,8);
            D(i).case(caseNum).run(runNum).phi     = R(:,9);
            D(i).case(caseNum).run(runNum).theta   = R(:,10);
            D(i).case(caseNum).run(runNum).psi     = R(:,11);
            D(i).case(caseNum).run(runNum).p       = R(:,12);
            D(i).case(caseNum).run(runNum).q       = R(:,13);
            D(i).case(caseNum).run(runNum).r       = R(:,14);
            D(i).case(caseNum).run(runNum).Agent_Th = R(:,15:18);
            D(i).case(caseNum).run(runNum).Total_Th = R(:,19:22);
            D(i).case(caseNum).run(runNum).xpos = R(:,23);
            D(i).case(caseNum).run(runNum).ypos = R(:,24);
            D(i).case(caseNum).run(runNum).zpos = R(:,25);
        end
    end
end

numCases = 4;
sigNames = ["x", "y", "z"];     % "x", "y", "z", "theta" 등

% figure; hold on; grid on;
colors = [1 0 0; 0 0 1; 0 0.6 0; 0 0 0];
% colors = [1 0 0; 0 0 1; 0 0.6 0];

for sig = 1:numel(sigNames)

    sigName = sigNames(sig);

    for c = 1:numCases
    
        figure('Name', sprintf('%s - Case %d', sigName, c)); 
        hold on; grid on;
    
        for i = 1:numel(D)
            t = D(i).case(c).run(1).t;
            t = t(:);
            runs = D(i).case(c).run;
            numRuns = numel(runs);
            N = length(t);
        
            Smat = nan(N, numRuns);
        
            for runNum = 1:numRuns
                Smat(:, runNum) = D(i).case(c).run(runNum).(sigName);
            end
        
            s_mean = mean(Smat, 2, "omitnan");
            s_std = std(Smat, 0, 2, "omitnan");
        
            upper = s_mean + s_std;
            lower = s_mean - s_std;
        
            fill([t; flipud(t)], [upper(:); flipud(lower(:))], colors(i,:), 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'HandleVisibility', 'off');
            plot(t, s_mean, 'Color',colors(i,:),'LineWidth', 1.8, 'DisplayName', D(i).label);
        end
    
        xlabel('Time [s]');
        ylabel(sigName);
        title(sprintf('Case %d: mean %s comparison', c, sigName));
        legend('Location', 'best');
    end
end

numAlg   = numel(D);
numCases = numel(D(1).case);

e_pos3DRMSEMeanMat = nan(numCases, numAlg);
e_pos3DRMSEStdMat  = nan(numCases, numAlg);

e_vel3DRMSEMeanMat = nan(numCases, numAlg);
e_vel3DRMSEStdMat  = nan(numCases, numAlg);

e_attRPRMSEMeanMat = nan(numCases, numAlg);
e_attRPRMSEStdMat  = nan(numCases, numAlg);

e_omegaRMSEMeanMat = nan(numCases, numAlg);
e_omegaRMSEStdMat  = nan(numCases, numAlg);

for i = 1:numAlg
    for c = 1:numCases
        runs = D(i).case(c).run;
        numRuns = numel(runs);

        pos3D_rmse_runs = nan(1, numRuns);
        vel3D_rmse_runs = nan(1, numRuns);
        attRP_rmse_runs = nan(1, numRuns);
        omega_rmse_runs = nan(1, numRuns);

        for runNum = 1:numRuns
            x     = D(i).case(c).run(runNum).x;
            y     = D(i).case(c).run(runNum).y;
            z     = D(i).case(c).run(runNum).z;
            evmag = D(i).case(c).run(runNum).e_v_mag;
            phi   = D(i).case(c).run(runNum).phi;
            theta = D(i).case(c).run(runNum).theta;
            psi   = D(i).case(c).run(runNum).psi;

            e_pos3D = sqrt(x.^2 + y.^2 + z.^2);
            e_vel3D = evmag;   % 네 정의에 따라 수정 가능
            e_attRP = sqrt(phi.^2 + theta.^2);
            e_omega = sqrt(phi.^2 + theta.^2 + psi.^2);   % 실제 의미가 attRPY라면

            pos3D_rmse_runs(runNum) = sqrt(mean(e_pos3D.^2, "omitnan"));
            vel3D_rmse_runs(runNum) = sqrt(mean(e_vel3D.^2, "omitnan"));
            attRP_rmse_runs(runNum) = sqrt(mean(e_attRP.^2, "omitnan"));
            omega_rmse_runs(runNum) = sqrt(mean(e_omega.^2, "omitnan"));
        end

        e_pos3DRMSEMeanMat(c, i) = mean(pos3D_rmse_runs, "omitnan");
        e_pos3DRMSEStdMat(c, i)  = std(pos3D_rmse_runs, 0, "omitnan");

        e_vel3DRMSEMeanMat(c, i) = mean(vel3D_rmse_runs, "omitnan");
        e_vel3DRMSEStdMat(c, i)  = std(vel3D_rmse_runs, 0, "omitnan");

        e_attRPRMSEMeanMat(c, i) = mean(attRP_rmse_runs, "omitnan");
        e_attRPRMSEStdMat(c, i)  = std(attRP_rmse_runs, 0, "omitnan");

        e_omegaRMSEMeanMat(c, i) = mean(omega_rmse_runs, "omitnan");
        e_omegaRMSEStdMat(c, i)  = std(omega_rmse_runs, 0, "omitnan");
    end
end

metricMeanCell = {e_pos3DRMSEMeanMat, e_vel3DRMSEMeanMat, ...
                  e_attRPRMSEMeanMat, e_omegaRMSEMeanMat};

metricStdCell  = {e_pos3DRMSEStdMat, e_vel3DRMSEStdMat, ...
                  e_attRPRMSEStdMat, e_omegaRMSEStdMat};

metricNames = ["e\_pos3D", "e\_vel3D", "e\_attRP", "e\_attRPY"];

for c = 1:numCases
    figure('Name', sprintf('Case %d RMSE Comparison', c));

    for s = 1:numel(metricNames)
        subplot(2,2,s);

        vals = metricMeanCell{s}(c, :);
        errs = metricStdCell{s}(c, :);
        x = 1:numel(vals);

        b = bar(x, vals, 'FaceColor', 'flat', 'EdgeColor', 'none');
        b.CData = colors(1:numel(vals), :);
        b.FaceAlpha = 0.5;

        hold on; grid on;
        errorbar(x, vals, errs, 'k', 'LineStyle', 'none', 'LineWidth', 1.2);

        set(gca, 'XTick', x, 'XTickLabel', labels);
        ylabel(metricNames(s) + " RMSE", 'Interpreter', 'none');
        title(sprintf('Case %d: %s', c, metricNames(s)), 'Interpreter', 'none');
    end

    sgtitle(sprintf('Case %d RMSE Comparison of Complex Metrics', c), ...
        'Interpreter', 'none');
end

caseNum = 1;          % case 1
sampleStep = 1;      % 10개마다 1개 샘플
shrinkFac = 0.8;      % boundary 수축 계수 (0~1), 필요시 조절

figure; subplot(1,2,1); hold on; grid on; 
% axis equal;

for i = 1:numel(D)
    runs = D(i).case(caseNum).run;
    numRuns = numel(runs);

    Xall = [];
    Yall = [];

    for runNum = 1:numRuns
        x = D(i).case(caseNum).run(runNum).x;
        y = D(i).case(caseNum).run(runNum).y;

        % 열벡터화
        x = x(:);
        y = y(:);

        % 10개마다 1개 샘플
        idx = 1:sampleStep:length(x);

        Xall = [Xall; x(idx)];
        Yall = [Yall; y(idx)];
    end

    % boundary 계산
    k = boundary(Xall, Yall, shrinkFac);

    % 점 없이 음영만 표시
    fill(Xall(k), Yall(k), colors(i,:), ...
        'FaceAlpha', 0.18, ...
        'EdgeColor', colors(i,:), ...
        'LineWidth', 1.5, ...
        'DisplayName', D(i).label);
end

plot(0,0,'kx','MarkerSize',10,'LineWidth',2, 'HandleVisibility', 'off')
xlabel('x [m]');
ylabel('y [m]');
title('Case 1: XY boundary region comparison');
legend('Location', 'best');

caseNum = 1;
sampleStep = 1;
shrinkFac = 0.8;

numAlg = numel(D);
boundaryArea = nan(1, numAlg);

for i = 1:numAlg
    runs = D(i).case(caseNum).run;
    numRuns = numel(runs);

    Xall = [];
    Yall = [];

    for runNum = 1:numRuns
        x = D(i).case(caseNum).run(runNum).x;
        y = D(i).case(caseNum).run(runNum).y;

        x = x(:);
        y = y(:);

        idx = 1:sampleStep:length(x);

        Xall = [Xall; x(idx)];
        Yall = [Yall; y(idx)];
    end

    k = boundary(Xall, Yall, shrinkFac);

    % boundary 내부 면적 계산
    boundaryArea(i) = polyarea(Xall(k), Yall(k));
end

subplot(1,2,2); hold on; grid on;

xbar = 1:numAlg;
b = bar(xbar, boundaryArea, 'FaceColor', 'flat', 'EdgeColor', 'none');
b.CData = colors(1:numAlg, :);
b.FaceAlpha = 0.5;

set(gca, 'XTick', xbar, 'XTickLabel', labels);
ylabel('Boundary Area [m^2]');
title(sprintf('Case %d: XY Boundary Area Comparison', caseNum));

clear Xall Yall

caseNum = 1;
sampleStep = 2;
numAlg = numel(D);

Xall = cell(1, numAlg);
Yall = cell(1, numAlg);
rmse_posh = zeros(1, numAlg);   % 각 알고리즘별 e_posh RMSE 저장

% ===== 데이터 모으기 + e_posh RMSE 계산 =====
for i = 1:numAlg
    runs = D(i).case(caseNum).run;
    numRuns = numel(runs);

    Xtmp = [];
    Ytmp = [];
    Etmp = [];   % e_posh 전체 샘플 저장

    for runNum = 1:numRuns
        x = runs(runNum).x(:);
        y = runs(runNum).y(:);

        idx = 1:sampleStep:length(x);

        x_s = x(idx);
        y_s = y(idx);

        Xtmp = [Xtmp; x_s];
        Ytmp = [Ytmp; y_s];

        e_posh = sqrt(x_s.^2 + y_s.^2);
        Etmp = [Etmp; e_posh];
    end

    Xall{i} = Xtmp;
    Yall{i} = Ytmp;

    % e_posh RMSE
    rmse_posh(i) = sqrt(mean(Etmp.^2, 'omitnan'));
end

% ===== 전체 범위 계산 =====
xmin = inf; xmax = -inf;
ymin = inf; ymax = -inf;

for i = 1:numAlg
    xmin = min(xmin, min(Xall{i}));
    xmax = max(xmax, max(Xall{i}));
    ymin = min(ymin, min(Yall{i}));
    ymax = max(ymax, max(Yall{i}));
end

xedges = linspace(xmin, xmax, 51);  % 40 bins
yedges = linspace(ymin, ymax, 51);

% ===== 공통 color scale 최대값 계산 =====
cmax = 0;

for i = 1:numAlg
    h = histogram2(Xall{i}, Yall{i}, ...
        xedges, yedges, ...
        'DisplayStyle','tile', ...
        'ShowEmptyBins','off', ...
        'Normalization','count');

    cmax = max(cmax, max(h.Values(:)));
    delete(h);
end

% ===== 원 설정 =====
delta_h = 0.07;               % Huber delta
th = linspace(0, 2*pi, 400);   % 원 좌표용 파라미터

% ===== 그림 =====
figure;

for i = 1:numAlg
    subplot(2,2,i);

    h = histogram2(Xall{i}, Yall{i}, ...
        xedges, yedges, ...
        'DisplayStyle','tile', ...
        'ShowEmptyBins','off', ...
        'Normalization','count');

    % 컬러맵
    n = 256;
    cmap = [linspace(1,1,n)', linspace(1,0,n)', linspace(1,0,n)']; % white→red
    colormap(gca, cmap)

    % 색상축
    clim([1 cmax])
    h.EdgeColor = [0 0 0];
    h.LineWidth = 0.1;

    colorbar
    grid on
    title(D(i).label);

    % axis equal
    xlim([xmin xmax])
    ylim([ymin ymax])

    hold on

    % ===== 1) Huber delta 원 =====
    xc_delta = delta_h * cos(th);
    yc_delta = delta_h * sin(th);
    plot(xc_delta, yc_delta, 'k--', 'LineWidth', 1.5, ...
        'DisplayName', sprintf('\\delta = %.3f', delta_h));

    % ===== 2) e_posh RMSE 원 =====
    r_rmse = rmse_posh(i);
    xc_rmse = r_rmse * cos(th);
    yc_rmse = r_rmse * sin(th);
    plot(xc_rmse, yc_rmse, 'b-', 'LineWidth', 1.8, ...
        'DisplayName', sprintf('RMSE = %.3f', r_rmse));

    % 중심점 표시 (선택)
    plot(0, 0, 'k+', 'LineWidth', 1.2, 'MarkerSize', 8);

    % legend는 첫 subplot에만 달아도 됨
    % if i == 1
    legend('show', 'Location', 'northeast')
    % end

    hold off
    xlabel("x error [m]");
    ylabel("y error [m]");
end
%% ===== Case 4: XY Trajectory Comparison (Figure-8) =====
caseIdx = 4; % 8자 항로 번호
figure('Name', 'Case 4: 8-figure Trajectory Plot', 'Color', 'w');
hold on; grid on;

axis equal; 

for i = 1:numel(D)
    x_traj = D(i).case(caseIdx).run(1).xpos;
    y_traj = D(i).case(caseIdx).run(1).ypos;

    plot(x_traj, y_traj, 'Color', colors(i,:), 'LineWidth', 2, 'DisplayName', D(i).label);
end

R_ref = 15;
A_8 = R_ref; B_8 = R_ref/2;
s_ref = linspace(0, 1, 500);
x_ref = A_8 * sin(2*pi*s_ref);
y_ref = B_8 * sin(4*pi*s_ref);
plot(x_ref, y_ref, 'k--', 'LineWidth', 1, 'DisplayName', 'Target Path');

xlabel('x [m]', 'FontSize', 12);
ylabel('y [m]', 'FontSize', 12);
title('Case 4: XY Trajectory Comparison (8-figure)', 'FontSize', 14);
legend('Location', 'northeastoutside');

% 원점 표시
plot(0, 0, 'k+', 'MarkerSize', 10, 'LineWidth', 1.5, 'HandleVisibility', 'off');

%% ================================
% Colored Box plot: case별 알고리즘 RMSE 분포
% ================================

numAlg   = numel(D);
numCases = numel(D(1).case);

metricNames = ["e_pos3D", "e_vel3D", "e_attRP", "e_attRPY"];

for c = 1:numCases

    figure('Name', sprintf('Case %d RMSE Boxplot', c));

    for s = 1:numel(metricNames)

        subplot(2,2,s);
        hold on; grid on;

        allVals   = [];
        allGroups = [];

        for i = 1:numAlg

            runs = D(i).case(c).run;
            numRuns = numel(runs);

            rmse_runs = nan(numRuns, 1);

            for runNum = 1:numRuns

                switch metricNames(s)

                    case "e_pos3D"
                        x = D(i).case(c).run(runNum).x;
                        y = D(i).case(c).run(runNum).y;
                        z = D(i).case(c).run(runNum).z;

                        e = sqrt(x.^2 + y.^2 + z.^2);

                    case "e_vel3D"
                        e = D(i).case(c).run(runNum).e_v_mag;

                    case "e_attRP"
                        phi   = D(i).case(c).run(runNum).phi;
                        theta = D(i).case(c).run(runNum).theta;

                        e = sqrt(phi.^2 + theta.^2);

                    case "e_attRPY"
                        phi   = D(i).case(c).run(runNum).phi;
                        theta = D(i).case(c).run(runNum).theta;
                        psi   = D(i).case(c).run(runNum).psi;

                        e = sqrt(phi.^2 + theta.^2 + psi.^2);
                end

                rmse_runs(runNum) = sqrt(mean(e.^2, "omitnan"));
            end

            allVals   = [allVals; rmse_runs];
            allGroups = [allGroups; repmat(i, numRuns, 1)];
        end

        for i = 1:numAlg
            idx = allGroups == i;

            boxchart(allGroups(idx), allVals(idx), ...
                'BoxFaceColor', colors(i,:), ...
                'BoxFaceAlpha', 0.4, ...
                'MarkerStyle', 'o');
        end

        set(gca, 'XTick', 1:numAlg, 'XTickLabel', labels);
        ylabel(metricNames(s) + " RMSE", 'Interpreter', 'none');
        title(sprintf('Case %d: %s RMSE', c, metricNames(s)), ...
            'Interpreter', 'none');

    end

    sgtitle(sprintf('Case %d RMSE Distribution by Algorithm', c), ...
        'Interpreter', 'none');
end

% %% ==========================================
% % Box plot: e_pos3D, e_vel3D를 case별 2x2 subplot으로 표시
% % Figure 1: e_pos3D RMSE
% % Figure 2: e_vel3D RMSE
% % Figure 3: e_attRPY RMSE, e_attRPY = sqrt(phi^2 + psi^2 + theta^2)
% % ==========================================
% 
% numAlg   = numel(D);
% numCases = numel(D(1).case);
% 
% targetMetrics = ["e_pos3D", "e_vel3D", "e_attRPY"];
% 
% for s = 1:numel(targetMetrics)
% 
%     metricName = targetMetrics(s);
% 
%     figure('Name', sprintf('%s RMSE Boxplot by Case', metricName));
% 
%     for c = 1:numCases
% 
%         subplot(2,2,c);
%         hold on; grid on;
% 
%         allVals   = [];
%         allGroups = [];
% 
%         for i = 1:numAlg
% 
%             runs = D(i).case(c).run;
%             numRuns = numel(runs);
% 
%             rmse_runs = nan(numRuns, 1);
% 
%             for runNum = 1:numRuns
% 
%                 switch metricName
% 
%                     case "e_pos3D"
%                         x = D(i).case(c).run(runNum).x;
%                         y = D(i).case(c).run(runNum).y;
%                         z = D(i).case(c).run(runNum).z;
% 
%                         e = sqrt(x.^2 + y.^2 + z.^2);
% 
%                     case "e_vel3D"
%                         e = D(i).case(c).run(runNum).e_v_mag;
% 
%                     case "e_attRPY"
%                         phi   = D(i).case(c).run(runNum).phi;
%                         theta = D(i).case(c).run(runNum).theta;
%                         psi   = D(i).case(c).run(runNum).psi;
% 
%                         e = sqrt(phi.^2 + psi.^2 + theta.^2);
%                 end
% 
%                 rmse_runs(runNum) = sqrt(mean(e.^2, "omitnan"));
%             end
% 
%             allVals   = [allVals; rmse_runs];
%             allGroups = [allGroups; repmat(i, numRuns, 1)];
%         end
% 
%         % 알고리즘별 boxchart
%         for i = 1:numAlg
%             idx = allGroups == i;
% 
%             boxchart(allGroups(idx), allVals(idx), ...
%                 'BoxFaceColor', colors(i,:), ...
%                 'BoxFaceAlpha', 0.4, ...
%                 'MarkerStyle', 'o');
%         end
% 
%         set(gca, 'XTick', 1:numAlg, 'XTickLabel', labels);
%         ylabel(metricName + " RMSE", 'Interpreter', 'none');
%         title(sprintf('Case %d', c), 'Interpreter', 'none');
% 
%     end
% 
%     sgtitle(sprintf('%s RMSE Distribution by Case and Algorithm', metricName), ...
%         'Interpreter', 'none');
% end


%% ==========================================
% Box plot: reward formulation comparison
% Figure 1: e_pos3D RMSE
% Figure 2: e_attRPY RMSE
%
% e_pos3D  = sqrt(x^2 + y^2 + z^2)
% e_attRPY = sqrt(phi^2 + theta^2 + psi^2)
% ==========================================

numAlg   = numel(D);
numCases = numel(D(1).case);

% 4.2 Reward Function Comparison에 사용할 핵심 지표
targetMetrics = ["e_pos3D", "e_attRPY"];

% 논문용 표시 이름
metricDisplayName = containers.Map;
metricDisplayName("e_pos3D")  = "3D Position RMSE";
metricDisplayName("e_attRPY") = "Three-Axis Attitude RMSE";

% y축 표시 이름
metricYLabel = containers.Map;
metricYLabel("e_pos3D")  = "3D position RMSE";
metricYLabel("e_attRPY") = "Three-axis attitude RMSE";

for s = 1:numel(targetMetrics)

    metricName = targetMetrics(s);

    figure('Name', sprintf('%s RMSE Boxplot by Case', metricName));

    for c = 1:numCases

        subplot(2,2,c);
        hold on; grid on;

        allVals   = [];
        allGroups = [];

        for i = 1:numAlg

            runs = D(i).case(c).run;
            numRuns = numel(runs);

            rmse_runs = nan(numRuns, 1);

            for runNum = 1:numRuns

                switch metricName

                    case "e_pos3D"
                        x = D(i).case(c).run(runNum).x;
                        y = D(i).case(c).run(runNum).y;
                        z = D(i).case(c).run(runNum).z;

                        e = sqrt(x.^2 + y.^2 + z.^2);

                    case "e_attRPY"
                        phi   = D(i).case(c).run(runNum).phi;
                        theta = D(i).case(c).run(runNum).theta;
                        psi   = D(i).case(c).run(runNum).psi;

                        e = sqrt(phi.^2 + theta.^2 + psi.^2);
                end

                rmse_runs(runNum) = sqrt(mean(e.^2, "omitnan"));
            end

            allVals   = [allVals; rmse_runs];
            allGroups = [allGroups; repmat(i, numRuns, 1)];
        end

        % Reward formulation별 boxchart
        for i = 1:numAlg
            idx = allGroups == i;

            boxchart(allGroups(idx), allVals(idx), ...
                'BoxFaceColor', colors(i,:), ...
                'BoxFaceAlpha', 0.4, ...
                'MarkerStyle', 'o');
        end

        set(gca, 'XTick', 1:numAlg, 'XTickLabel', labels);
        ylabel(metricYLabel(metricName), 'Interpreter', 'none');
        title(sprintf('Case %d', c), 'Interpreter', 'none');

    end

    sgtitle(sprintf('%s by Reward Formulation', ...
        metricDisplayName(metricName)), ...
        'Interpreter', 'none');
end