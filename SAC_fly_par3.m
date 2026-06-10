
clc; clear; close all; delete('*.dat');

%% =========================================================
%% 0) 기본 설정
%% =========================================================
mdl = "vector";
open_system(mdl);
rng(0,'twister');

Ts = 0.05;
Tf = 30;

percent = 0.02; % ==== 추력 범위 설정 =====
percent_str = compose("%.3g", percent);

select_num = "1";
blk_select = mdl + "/Hybrid RL-PD Control System/Select";
set_param(blk_select, "Value", select_num);
select = str2double(select_num);

rootDir = "result";
datRoot = fullfile(rootDir, "실험 결과 dat 파일 모음");
matRoot = fullfile(rootDir, "실험 결과 mat 파일 모음");
txtRoot = fullfile(rootDir, "실험 조건 txt 파일 모음");

% reward_order:
% 1 = Scaled L1, L = delta*abs(e)
% 2 = L2,        L = 0.5*e^2
% 3 = Huber
reward_order = "1";
reward_shape_blk = mdl + "/Reward/Num";
set_param(reward_shape_blk, "Value", reward_order);
reward_shape = str2double(reward_order);

if reward_shape == 1
    fname = "(cpu1)(ScaledL1)(" + percent_str + ")SAC_ver1(mod_" + string(select) + ")";
elseif reward_shape == 2
    fname = "(cpu1)(L2)(" + percent_str + ")SAC_ver1(mod_" + string(select) + ")";
elseif reward_shape == 3
    fname = "(cpu1)(Huber)(" + percent_str + ")SAC_ver6(mod_" + string(select) + ")";
else
    error("Invalid reward_order. Use '1' for L1, '2' for L2, or '3' for Huber.");
end

if ~exist(datRoot,'dir'); mkdir(datRoot); end
if ~exist(matRoot,'dir'); mkdir(matRoot); end
if ~exist(txtRoot,'dir'); mkdir(txtRoot); end

datDir = fullfile(datRoot, fname);
if ~exist(datDir, 'dir'); mkdir(datDir); end

%% =========================================================
%% 1) GPU / 병렬풀 설정
%% =========================================================
useGPU = canUseGPU();
useParallel = true;   % 필요 없으면 false로 바꿔도 됨

if useGPU
    try
        g = gpuDevice(1);
        reset(g);   % 시작 전 GPU 메모리 초기화
        disp("GPU 사용: " + string(g.Name));
        deviceType = "gpu";
    catch ME
        warning("GPU 초기화 실패. CPU로 진행합니다.\n%s", ME.message);
        deviceType = "cpu";
        useGPU = false;
    end
else
    disp("사용 가능한 GPU가 없어 CPU로 진행합니다.");
    deviceType = "cpu";
end

if useParallel
    p = gcp('nocreate');
    if ~isempty(p)
        delete(p);
    end
    parpool("Processes");
end

%% =========================================================
%% 2) 환경 파라미터 읽기
%% =========================================================
blk_m = mdl + "/Hybrid RL-PD Control System/Mass";
blk_g = mdl + "/Hybrid RL-PD Control System/Gravity";
blk_percent = mdl + "/Hybrid RL-PD Control System/Percent";

m = str2double(get_param(blk_m, "Value"));
g = str2double(get_param(blk_g, "Value"));


set_param(blk_percent, "Value", num2str(percent));

Thrust_limit = 1.5 * m * g;

action_low  = Thrust_limit * -percent;
action_high = Thrust_limit *  percent;

actScale = (action_high - action_low)/2;
actBias = 0;

%% =========================================================
%% 3) Observation / Action Spec
%% =========================================================
obsInfo = rlNumericSpec([12 1]);
obsInfo.Name = "observation";

actInfo = rlNumericSpec([4 1], ...
    LowerLimit=[action_low action_low action_low action_low]', ...
    UpperLimit=[action_high action_high action_high action_high]');
actInfo.Name = "thrust_action";

%% =========================================================
%% 4) Simulink RL Environment
%% =========================================================
env = rlSimulinkEnv(mdl, mdl + "/RL Agent", obsInfo, actInfo);
env.ResetFcn = @(in)localReset(in, mdl);

% 반복 학습 시 컴파일 오버헤드 감소
env.UseFastRestart = "on";

%% =========================================================
%% 5) Actor / Critic 생성
%% =========================================================
actor = actorMaker(obsInfo, actInfo, deviceType, actScale, actBias);

CriticNet1 = criticMaker(obsInfo, actInfo);
CriticNet2 = criticMaker(obsInfo, actInfo);

critic1 = rlQValueFunction(initialize(CriticNet1), obsInfo, actInfo, ...
    ObservationInputNames="obsInput", ...
    ActionInputNames="actInput", ...
    UseDevice=deviceType);

critic2 = rlQValueFunction(initialize(CriticNet2), obsInfo, actInfo, ...
    ObservationInputNames="obsInput", ...
    ActionInputNames="actInput", ...
    UseDevice=deviceType);

critic = [critic1 critic2];

%% =========================================================
%% 6) SAC Agent 옵션
%% =========================================================
agentOpts = rlSACAgentOptions;
agentOpts.SampleTime = Ts;
agentOpts.DiscountFactor = 0.99;
agentOpts.MiniBatchSize = 128;
agentOpts.ExperienceBufferLength = 1e6;
agentOpts.TargetSmoothFactor = 0.005;

[agentOpts.CriticOptimizerOptions.LearnRate] = deal(1e-3);
agentOpts.ActorOptimizerOptions.LearnRate = 5e-4;

agentOpts.EntropyWeightOptions.LearnRate = 1e-3;
agentOpts.EntropyWeightOptions.EntropyWeight = 1.0;
agent = rlSACAgent(actor, critic, agentOpts);

%% =========================================================
%% 7) Training 옵션
%% =========================================================
trainOpts = rlTrainingOptions( ...
    MaxEpisodes=3000, ...
    MaxStepsPerEpisode=ceil(Tf/Ts), ...
    Plots="training-progress", ...
    Verbose=false, ...
    StopTrainingCriteria="none");

if useParallel
    trainOpts.UseParallel = true;

    % SAC는 off-policy라 async 모드가 일반적으로 잘 맞는 편
    trainOpts.ParallelizationOptions.Mode = "async";

    % 경험 수집 단위 (기본값으로도 가능)
    % trainOpts.ParallelizationOptions.StepsUntilDataIsSent = 32;
end

%% =========================================================
%% 8) 메모 저장
%% =========================================================
writeMemo_flat(fname, mdl, txtRoot, deviceType, useParallel);

%% =========================================================
%% 8.5) Episode logger 설정
%% =========================================================
% logDir = fullfile(datDir, "episode_logs");
% if ~exist(logDir,'dir'); mkdir(logDir); end
% 
% logger = rlDataLogger();
% logger.LoggingOptions.LoggingDirectory = logDir;
% logger.LoggingOptions.FileNameRule = "episode<id>";
% logger.EpisodeFinishedFcn = @episodeFinishedFcn;

%% =========================================================
%% 9) 학습 실행
%% =========================================================
evl = rlEvaluator(EvaluationFrequency=50, NumEpisodes=10, UseExplorationPolicy=false);

trainingStats = train(agent, env, trainOpts, Evaluator=evl);

trainedAgent = agent;


%% =========================================================
%% 10) 결과 저장
%% =========================================================
save(fullfile(matRoot, fname + ".mat"), ...
    "trainedAgent", "trainingStats", "Ts", "Tf", ...
    "deviceType", "useParallel");

R = trainingStats.EpisodeReward;
I = trainingStats.EpisodeIndex;
Q = trainingStats.EpisodeQ0;

save(fullfile(datDir, 'EpisodeReward.dat'), 'R', '-ascii');
save(fullfile(datDir, 'EpisodeIndex.dat'),  'I', '-ascii');
save(fullfile(datDir, 'EpisodeQ0.dat'),     'Q', '-ascii');

disp("학습 및 저장 완료");
delete(gcp('nocreate'));
%% =========================================================
%% Local Functions
%% =========================================================
function in = localReset(in, mdl)
    % dry_blk = mdl + "/Drone System/Wind";
    num = randn(1,1);
    % num = zeros(8,1);
    % new_seeds = randi([10000, 99999], 1, 4);
    % set_param(dry_blk, "Seed", mat2str(new_seeds));

    blk1 = mdl + "/Hybrid RL-PD Control System/Wind/Seed";
    in = setBlockParameter(in, blk1, "Value", mat2str(num));

end

function actor = actorMaker(obsInfo, actInfo, deviceType, actScale, actBias)

    numObs = prod(obsInfo.Dimension);
    numAct = prod(actInfo.Dimension);

    actScale = ones(numAct, 1) * actScale;
    actBias  = ones(numAct, 1) * actBias;

    trunk = [
        featureInputLayer(numObs, Name="obsInput")
        fullyConnectedLayer(128, Name="fc1")
        reluLayer(Name="relu1")
        fullyConnectedLayer(128, Name="fc2")
        reluLayer(Name="relu2")
    ];

    muHead = [
        fullyConnectedLayer(numAct, Name="mu_In")
        tanhLayer(Name="mu_tanh")
        scalingLayer(Name="mu_out", Scale=actScale, Bias=actBias)
    ];

    stdHead = [
        fullyConnectedLayer(numAct, Name="std_In")
        softplusLayer(Name="std_soft")
        scalingLayer(Name="sig_out", ...
            Scale=0.1*ones(numAct,1), ...
            Bias=0.001*ones(numAct,1))
    ];

    lg = layerGraph(trunk);
    lg = addLayers(lg, muHead);
    lg = addLayers(lg, stdHead);

    lg = connectLayers(lg, "relu2", "mu_In");
    lg = connectLayers(lg, "relu2", "std_In");

    net = dlnetwork(lg);

    actor = rlContinuousGaussianActor(net, obsInfo, actInfo, ...
        ActionMeanOutputNames="mu_out", ...
        ActionStandardDeviationOutputNames="sig_out", ...
        ObservationInputNames="obsInput", ...
        UseDevice=deviceType);

end

function criticNet = criticMaker(obsInfo, actInfo)

    numObs = prod(obsInfo.Dimension);
    numAct = prod(actInfo.Dimension);

    obsLayer = featureInputLayer(numObs, Name="obsInput");
    actLayer = featureInputLayer(numAct, Name="actInput");

    criticCore = [
        concatenationLayer(1, 2, Name="concat")
        fullyConnectedLayer(128, Name="fc1")
        reluLayer(Name="relu1")
        fullyConnectedLayer(128, Name="fc2")
        reluLayer(Name="relu2")
        fullyConnectedLayer(1, Name="Q_value")
    ];

    lg = layerGraph(obsLayer);
    lg = addLayers(lg, actLayer);
    lg = addLayers(lg, criticCore);

    lg = connectLayers(lg, "obsInput", "concat/in1");
    lg = connectLayers(lg, "actInput", "concat/in2");

    criticNet = dlnetwork(lg);

end

function writeMemo_flat(fname, mdl, txtRoot, deviceType, useParallel)

    if ~exist(txtRoot,'dir'); mkdir(txtRoot); end

    notePath = fullfile(txtRoot, fname + "_memo.txt");
    fid = fopen(notePath, 'w');
    assert(fid ~= -1, "Cannot open memo file: %s", notePath);

    load_system(mdl);

    t = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
    fprintf(fid, "실험명: %s\n", fname);
    fprintf(fid, "날짜: %s\n", string(t));
    fprintf(fid, "학습 디바이스: %s\n", deviceType);
    fprintf(fid, "병렬 학습 사용: %d\n", useParallel);

    Total_weight_value = get_param(mdl + "/Reward/Total Weight", "Value");
    Loss_x_Gain = get_param(mdl + "/Reward/Loss_x Gain", "Gain");
    Loss_y_Gain = get_param(mdl + "/Reward/Loss_y Gain", "Gain");
    Loss_z_Gain = get_param(mdl + "/Reward/Loss_z Gain", "Gain");
    e_v_dir_Gain = get_param(mdl + "/Reward/e_v_dir Gain", "Gain");
    e_v_mag_Gain = get_param(mdl + "/Reward/e_v_mag Gain", "Gain");
    Loss_phi_Gain = get_param(mdl + "/Reward/phi Gain", "Gain");
    Loss_theta_Gain = get_param(mdl + "/Reward/theta Gain", "Gain");
    Loss_psi_Gain = get_param(mdl + "/Reward/psi Gain", "Gain");
    Loss_p_Gain = get_param(mdl + "/Reward/p Gain", "Gain");
    Loss_q_Gain = get_param(mdl + "/Reward/q Gain", "Gain");
    Loss_r_Gain = get_param(mdl + "/Reward/r Gain", "Gain");

    fprintf(fid, "Total weight 값 : %s \n\n", Total_weight_value);
    fprintf(fid, "(Reward 블럭)Loss_x의 게인: %s\n", Loss_x_Gain);
    fprintf(fid, "(Reward 블럭)Loss_y의 게인: %s\n", Loss_y_Gain);
    fprintf(fid, "(Reward 블럭)Loss_z의 게인: %s\n", Loss_z_Gain);
    fprintf(fid, "(Reward 블럭)e_v_dir의 게인: %s\n", e_v_dir_Gain);
    fprintf(fid, "(Reward 블럭)e_v_mag의 게인: %s\n", e_v_mag_Gain);
    fprintf(fid, "(Reward 블럭)Loss_phi의 게인: %s\n", Loss_phi_Gain);
    fprintf(fid, "(Reward 블럭)Loss_theta의 게인: %s\n", Loss_theta_Gain);
    fprintf(fid, "(Reward 블럭)Loss_psi의 게인: %s\n", Loss_psi_Gain);
    fprintf(fid, "(Reward 블럭)Loss_p의 게인: %s\n", Loss_p_Gain);
    fprintf(fid, "(Reward 블럭)Loss_q의 게인: %s\n", Loss_q_Gain);
    fprintf(fid, "(Reward 블럭)Loss_r의 게인: %s\n", Loss_r_Gain);

    fclose(fid);

end

% function dataToLog = episodeFinishedFcn(data)
% % 에피소드가 끝날 때마다 자동 호출됨
% % data.SimulationInfo : Simulink.SimulationOutput (Simulink 환경일 때)
% 
%     simOut = data.SimulationInfo;
% 
%     dataToLog = struct();
%     dataToLog.EpisodeCount  = data.EpisodeCount;
%     dataToLog.EpisodeReward = data.EpisodeInfo.CumulativeReward;
%     dataToLog.StepsTaken    = data.EpisodeInfo.StepsTaken;
% 
%     % logsout에서 signal 꺼내기
%     logs = simOut.logsout;
% 
%     % step-by-step penalty 신호를 꺼내서 episode별 sum 계산
%     dataToLog.SumPos  = sum(getSignalData(logs, "r_pos"),  "omitnan");
%     dataToLog.SumVel  = sum(getSignalData(logs, "r_v"),  "omitnan");
%     dataToLog.SumTheta = sum(getSignalData(logs, "r_theta"),  "omitnan");
%     dataToLog.SumThdot = sum(getSignalData(logs, "r_thdot"),  "omitnan");
% end
% 
% function x = getSignalData(logs, sigName)
% % logsout에서 signal 이름으로 데이터를 꺼내는 helper
% 
%     sig = logs.get(sigName);
% 
%     % timeseries 기준
%     if isa(sig.Values, "timeseries")
%         x = squeeze(sig.Values.Data);
%     else
%         % dataset/배열 형태 대비
%         x = squeeze(sig.Values.Data);
%     end
% 
%     x = double(x(:));
% end