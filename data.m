clc; clear; close all;

%% 0) 기본 설정
mdl = "vector";
open_system(mdl);

Tf = 30;
numRuns = 30;
casenum = 4;

rootDir = "result";
matRoot = fullfile(rootDir, "실험 결과 mat 파일 모음");
datRoot = fullfile(rootDir, "실험 결과 dat 파일 모음");

fname = "(Huber)TD3_ver1(mod_1)";
matFile = fullfile(matRoot, fname + ".mat");

if ~exist(datRoot, "dir")
    mkdir(datRoot);
end

datDir = fullfile(datRoot, fname + "(sine)");
if ~exist(datDir, "dir")
    mkdir(datDir);
end

outFile  = fullfile(datDir, fname + "_all_runs.dat");
seedFile = fullfile(datDir, fname + "_seed_list.dat");

if exist(outFile, "file")
    delete(outFile);
end
if exist(seedFile, "file")
    delete(seedFile);
end

%% 1) agent 로드
S = load(matFile);

if isfield(S, "trainedAgent")
    loadedAgent = S.trainedAgent;
elseif isfield(S, "agent")
    loadedAgent = S.agent;
else
    error("mat 파일 안에 trainedAgent 또는 agent 변수가 없습니다.");
end

%% 2) RL Agent 주입
agentBlk = mdl + "/RL Agent";
agentVarName = string(get_param(agentBlk, "Agent"));
assignin("base", agentVarName, loadedAgent);

fprintf("RL Agent block variable name: %s\n", agentVarName);

%% 3) 시뮬레이션 설정
set_param(mdl, "StopTime", num2str(Tf));
set_param(mdl, "FastRestart", "off");

seedBlk = mdl + "/Hybrid RL-PD Control System/Wind/Seed";
caseBlk = mdl + "/Hybrid RL-PD Control System/Select";

percent = 0.02;
% percent_str = compose("%.3g", percent);

percentBlk = mdl + "/Hybrid RL-PD Control System/Percent";
set_param(percentBlk, "Value", num2str(percent));

%% 4) 공통 seed 생성
rng(0,"twister");
seedList = randi([1 100000], numRuns, 1);

%% 5) dat 파일 헤더
fid = fopen(outFile, "a");
fprintf(fid, "%% run\tcase_Num\tt\tx\ty\tz\te_v_dir\te_v_mag\tphi\ttheta\tpsi\tp\tq\tr\tAgent_Th1\tAgent_Th2\tAgent_Th3\tAgent_Th4\tTotal_Th1\tTotal_Th2\tTotal_Th3\tTotal_Th4\tx_pos\ty_pos\tz_pos\tx_vel\ty_vel\tz_vel\tx_vel_cmd\ty_vel_cmd\tz_vel_cmd\n");
fclose(fid);

%% 6) 반복 실행
fprintf("%s data 뽑기 시작\n", fname);

for i = 1:casenum
    set_param(caseBlk, "Value", num2str(i));
    fprintf("\nCase %d 시작\n", i);

    for k = 1:numRuns
        seedVal = seedList(k);
        set_param(seedBlk, "Value", num2str(seedVal));

        fprintf("Run %d / %d, Seed = %d\n", k, numRuns, seedVal);

        simOut = sim(mdl);

        x_log       = simOut.get("x_err_log");
        y_log       = simOut.get("y_err_log");
        z_log       = simOut.get("z_err_log");
        e_v_dir_log = simOut.get("e_v_dir_log");
        e_v_mag_log = simOut.get("e_v_mag_log");
        phi_log     = simOut.get("phi_err_log");
        theta_log   = simOut.get("theta_err_log");
        psi_log     = simOut.get("psi_err_log");
        p_log       = simOut.get("p_err_log");
        q_log       = simOut.get("q_err_log");
        r_log       = simOut.get("r_err_log");

        x_pos_log   = simOut.get("x_log");
        y_pos_log   = simOut.get("y_log");
        z_pos_log   = simOut.get("z_log");

        vx_log      = simOut.get("vx_log");
        vy_log      = simOut.get("vy_log");
        vz_log      = simOut.get("vz_log");
        vx_cmd_log  = simOut.get("vx_cmd_log");
        vy_cmd_log  = simOut.get("vy_cmd_log");
        vz_cmd_log  = simOut.get("vz_cmd_log");

        Agent_Th1_log = simOut.get("Agent_Th1");
        Agent_Th2_log = simOut.get("Agent_Th2");
        Agent_Th3_log = simOut.get("Agent_Th3");
        Agent_Th4_log = simOut.get("Agent_Th4");
        Total_Th1_log = simOut.get("Total_Th1");
        Total_Th2_log = simOut.get("Total_Th2");
        Total_Th3_log = simOut.get("Total_Th3");
        Total_Th4_log = simOut.get("Total_Th4");

        t       = double(x_log.Time(:));
        x       = double(x_log.Data(:));
        y       = double(y_log.Data(:));
        z       = double(z_log.Data(:));
        e_v_dir = double(e_v_dir_log.Data(:));
        e_v_mag = double(e_v_mag_log.Data(:));
        phi     = double(phi_log.Data(:));
        theta   = double(theta_log.Data(:));
        psi     = double(psi_log.Data(:));
        p       = double(p_log.Data(:));
        q       = double(q_log.Data(:));
        r       = double(r_log.Data(:));

        x_pos = double(x_pos_log.Data(:));
        y_pos = double(y_pos_log.Data(:));
        z_pos = double(z_pos_log.Data(:));

        x_vel = double(vx_log.Data(:));
        y_vel = double(vy_log.Data(:));
        z_vel = double(vz_log.Data(:));

        x_vel_cmd = double(vx_cmd_log.Data(:));
        y_vel_cmd = double(vy_cmd_log.Data(:));
        z_vel_cmd = double(vz_cmd_log.Data(:));

        Agent_Th1 = double(Agent_Th1_log.Data(:));
        Agent_Th2 = double(Agent_Th2_log.Data(:));
        Agent_Th3 = double(Agent_Th3_log.Data(:));
        Agent_Th4 = double(Agent_Th4_log.Data(:));
        Total_Th1 = double(Total_Th1_log.Data(:));
        Total_Th2 = double(Total_Th2_log.Data(:));
        Total_Th3 = double(Total_Th3_log.Data(:));
        Total_Th4 = double(Total_Th4_log.Data(:));

        N = min([length(t), length(x), length(y), length(z), ...
                 length(e_v_dir), length(e_v_mag), ...
                 length(phi), length(theta), length(psi), ...
                 length(p), length(q), length(r), ...
                 length(Agent_Th1), length(Agent_Th2), length(Agent_Th3), length(Agent_Th4), ...
                 length(Total_Th1), length(Total_Th2), length(Total_Th3), length(Total_Th4), ...
                 length(x_pos), length(y_pos), length(z_pos), ...
                 length(x_vel), length(y_vel), length(z_vel), ...
                 length(x_vel_cmd), length(y_vel_cmd), length(z_vel_cmd)]);

        logMat = [ ...
            k*ones(N,1), ...
            i*ones(N,1), ...
            t(1:N), x(1:N), y(1:N), z(1:N), e_v_dir(1:N), e_v_mag(1:N), ...
            phi(1:N), theta(1:N), psi(1:N), p(1:N), q(1:N), r(1:N), ...
            Agent_Th1(1:N), Agent_Th2(1:N), Agent_Th3(1:N), Agent_Th4(1:N), ...
            Total_Th1(1:N), Total_Th2(1:N), Total_Th3(1:N), Total_Th4(1:N), ...
            x_pos(1:N), y_pos(1:N), z_pos(1:N), ...
            x_vel(1:N), y_vel(1:N), z_vel(1:N), ...
            x_vel_cmd(1:N), y_vel_cmd(1:N), z_vel_cmd(1:N)];

        writematrix(logMat, outFile, "Delimiter", "tab", "WriteMode", "append");
    end
end

%% 7) 공통 seed 목록 저장
seedMat = [(1:numRuns)', seedList];
writematrix(seedMat, seedFile, "Delimiter", "tab");

disp("모든 case/run 완료 및 dat 저장 완료.");