clc; clear;

expNames = [
    "No Agent(mod_1)"
    "(0.02)DDPG_ver4(mod_1)"
    "(0.02)TD3_ver3(mod_1)"
    "(0.02)SAC_ver15(mod_1)"
];

labels = [
    "No Agent"
    "DDPG"
    "TD3"
    "SAC"
];

nexp = numel(expNames);

for i = 1:nexp
    fname = expNames(i);
    rootDir = "result";
    expDir = fullfile(rootDir, "실험 결과 dat 파일 모음");
    datDir = fullfile(expDir, fname);
    expdata = fullfile(datDir, fname + "_all_runs.dat");

    M = readmatrix(expdata);

    idx = (M(:,2) == 2);
    M_case2 = M(idx,:);

    runList = unique(M_case2(:,1));

    D(i).name = labels(i);
    D(i).fname = fname;

    for j = 1:numel(runList)
        runNum = runList(j);

        idxrun = (M_case2(:,1) == runNum);
        R = M_case2(idxrun,:);

        D(i).run(j).runNum = runNum;
        D(i).run(j).t = R(:,3);
        D(i).run(j).x = R(:,4);
        D(i).run(j).y = R(:,5);
        D(i).run(j).z = R(:,6);
        D(i).run(j).e_v_dir = R(:,7);
        D(i).run(j).e_v_mag = R(:,8);
        D(i).run(j).phi = R(:,9);
        D(i).run(j).theta = R(:,10);
        D(i).run(j).psi = R(:,11);
        D(i).run(j).p = R(:,12);
        D(i).run(j).q = R(:,13);
        D(i).run(j).r = R(:,14);
        D(i).run(j).Agent_Th = R(:,15:18);
        D(i).run(j).Total_Th = R(:,19:22);
        D(i).run(j).pos = R(:,23:25);
        D(i).run(j).vel = R(:,26:28);
        D(i).run(j).vel_cmd = R(:,29:31);
    end
end

numRuns = numel(runList);

% =========================
% 2) 축별 평균 속도오차 plot
% =========================
compNames = ["x", "y", "z"];

for k = 1:3
    figure; hold on;

    for i = 1:nexp
        numRuns = numel(D(i).run);
        t = D(i).run(1).t;   % 모든 run 시간축이 같다고 가정

        % 시간길이 N, run 개수 numRuns
        N = length(t);
        errMat = nan(N, numRuns);

        for j = 1:numRuns
            vel     = D(i).run(j).vel;
            vel_cmd = D(i).run(j).vel_cmd;

            errVel = vel_cmd(:,k) - vel(:,k);
            errMat(:,j) = errVel;
        end

        errMean = mean(errMat, 2, "omitnan");
        errStd  = std(errMat, 0, 2, "omitnan");

        % 평균만 먼저 그리기
        plot(t, errMean, 'LineWidth', 1.5, 'DisplayName', labels(i));

        % 평균±표준편차까지 보고 싶으면 아래 fill 사용
        fill([t; flipud(t)], ...
             [errMean-errStd; flipud(errMean+errStd)], ...
             [0.8 0.8 0.8], ...
             'FaceAlpha', 0.3, ...
             'EdgeColor', 'none', ...
             'HandleVisibility', 'off');
    end

    grid on;
    xlabel('Time [s]');
    ylabel(compNames(k) + " velocity error");
    title("Case 2: " + compNames(k) + " velocity error mean");
    legend('Location', 'best');
    hold off;
end