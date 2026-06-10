%% analyze_training_q0_reward.m
% ============================================================
% Q0 / EpisodeReward 분석 코드
% 목적:
% 1) 알고리즘별 learning curve 확인
% 2) Q0와 실제 episode reward/return 비교
% 3) Q0 bias = Q0 - EpisodeReward 분석
%
% 요구 파일:
% result/실험 결과 dat 파일 모음/<agentName>/EpisodeIndex.dat
% result/실험 결과 dat 파일 모음/<agentName>/EpisodeQ0.dat
% result/실험 결과 dat 파일 모음/<agentName>/EpisodeReward.dat
% ============================================================

clc; clear; close all;

%% ============================================================
% 0) 사용자 설정
% ============================================================

rootDir = 'result';
datRoot = fullfile(rootDir, '실험 결과 dat 파일 모음');

agentNames = { ...
    '(0.02)DDPG_ver4(mod_1)', ...
    '(0.02)SAC_ver15(mod_1)' ...
    '(Huber)(0.02)SAC_ver1(mod_1)2' ...

};

agentLabels = { ...
    'DDPG', ...
    'SAC1', ...
    'SAC2' ...
};

% 이동평균 window
smoothWindow = 20;

% 결과 저장 폴더
outDir = fullfile(rootDir, 'q0_reward_analysis_result');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

% 색상
colors = [ ...
    0.8500 0.3250 0.0980;  % DDPG
    0.0000 0.4470 0.7410;  % TD3
    0.4660 0.6740 0.1880]; % SAC

%% ============================================================
% 1) 데이터 로드
% ============================================================

D = struct();
validAlg = false(numel(agentNames), 1);

for i = 1:numel(agentNames)

    agentName = agentNames{i};
    agentLabel = agentLabels{i};

    agentDir = fullfile(datRoot, agentName);

    indexFile  = fullfile(agentDir, 'EpisodeIndex.dat');
    q0File     = fullfile(agentDir, 'EpisodeQ0.dat');
    rewardFile = fullfile(agentDir, 'EpisodeReward.dat');

    fprintf('\n============================================================\n');
    fprintf('Loading: %s\n', agentLabel);
    fprintf('Folder : %s\n', agentDir);
    fprintf('============================================================\n');

    if ~isfile(indexFile)
        warning('EpisodeIndex.dat 없음: %s', indexFile);
        continue;
    end

    if ~isfile(q0File)
        warning('EpisodeQ0.dat 없음: %s', q0File);
        continue;
    end

    if ~isfile(rewardFile)
        warning('EpisodeReward.dat 없음: %s', rewardFile);
        continue;
    end

    epIdx = readDatVector(indexFile);
    rew   = readDatVector(rewardFile);
    
    [q0Raw, q0Col] = readQ0ValueAuto(q0File);
    
    % EpisodeIndex와 EpisodeReward는 full length 유지
    Nfull = min(numel(epIdx), numel(rew));
    
    epIdx = epIdx(1:Nfull);
    rew   = rew(1:Nfull);
    
    % Q0는 full length에 맞춰 NaN padding
    q0 = nan(Nfull, 1);
    
    Nq = min(numel(q0Raw), Nfull);
    q0(1:Nq) = q0Raw(1:Nq);
    
    % bias는 Q0가 있는 곳에서만 계산됨
    bias = q0 - rew;
    
    D(i).name = agentName;
    D(i).label = agentLabel;
    D(i).episode = epIdx;
    D(i).q0 = q0;
    D(i).reward = rew;
    D(i).bias = bias;
    D(i).q0Col = q0Col;
    
    validAlg(i) = true;
    
    fprintf('Loaded reward episodes: %d\n', sum(~isnan(rew)));
    fprintf('Loaded valid Q0 episodes: %d\n', sum(~isnan(q0)));
    fprintf('Selected Q0 column: %d\n', q0Col);
    fprintf('Mean Q0      = %.4f\n', mean(q0, 'omitnan'));
    fprintf('Mean Reward  = %.4f\n', mean(rew, 'omitnan'));
    fprintf('Mean Bias    = %.4f\n', mean(bias, 'omitnan'));

    D(i).name = agentName;
    D(i).label = agentLabel;
    D(i).episode = epIdx;
    D(i).q0 = q0;
    D(i).reward = rew;
    D(i).bias = bias;

    validAlg(i) = true;

    fprintf('Loaded episodes: %d\n', numel(epIdx));
    fprintf('Mean Q0      = %.4f\n', mean(q0, 'omitnan'));
    fprintf('Mean Reward  = %.4f\n', mean(rew, 'omitnan'));
    fprintf('Mean Bias    = %.4f\n', mean(bias, 'omitnan'));
end

D = D(validAlg);
agentLabels = agentLabels(validAlg);
colors = colors(validAlg, :);

if isempty(D)
    error('불러온 알고리즘 데이터가 없습니다. 파일 경로와 이름을 확인하세요.');
end

numAlg = numel(D);

%% ============================================================
% 2) 학습 곡선: EpisodeReward
% ============================================================

figure('Name', 'Learning Curve - Episode Reward', 'Color', 'w');
hold on; grid on; box on;

for i = 1:numAlg
    ep = D(i).episode;
    rew = D(i).reward;

    rewSmooth = movmean(rew, smoothWindow, 'omitnan');

    plot(ep, rewSmooth, ...
        'Color', colors(i,:), ...
        'LineWidth', 2.0, ...
        'DisplayName', D(i).label);
end

xlabel('Episode');
ylabel(sprintf('Episode reward, moving average window = %d', smoothWindow));
title('Learning Curve: Episode Reward');
legend('Location', 'best');
set(gca, 'FontSize', 11);

outPng = fullfile(outDir, 'learning_curve_episode_reward.png');
saveFigure(outPng);

%% ============================================================
% 3) Q0 vs EpisodeReward 곡선
% ============================================================

figure('Name', 'Q0 vs Episode Reward', 'Color', 'w');

for i = 1:numAlg
    subplot(numAlg, 1, i);
    hold on; grid on; box on;

    ep = D(i).episode;
    q0 = D(i).q0;
    rew = D(i).reward;

    q0Smooth = movmean(q0, smoothWindow, 'omitnan');
    rewSmooth = movmean(rew, smoothWindow, 'omitnan');

    plot(ep, q0Smooth, ...
        'Color', [0.8500 0.3250 0.0980], ...
        'LineWidth', 1.8, ...
        'DisplayName', 'Q0');

    plot(ep, rewSmooth, ...
        'Color', [0.0000 0.4470 0.7410], ...
        'LineWidth', 1.8, ...
        'DisplayName', 'Episode reward');

    ylabel(D(i).label);
    title(sprintf('%s: Q0 vs Episode Reward', D(i).label));
    legend('Location', 'best');
end

xlabel('Episode');
sgtitle(sprintf('Q0 and Episode Reward, moving average window = %d', smoothWindow));

outPng = fullfile(outDir, 'q0_vs_episode_reward.png');
saveFigure(outPng);

%% ============================================================
% 4) Q0 bias 곡선: bias = Q0 - reward
% ============================================================

figure('Name', 'Q0 Bias Curve', 'Color', 'w');
hold on; grid on; box on;

for i = 1:numAlg
    ep = D(i).episode;
    bias = D(i).bias;

    biasSmooth = movmean(bias, smoothWindow, 'omitnan');

    plot(ep, biasSmooth, ...
        'Color', colors(i,:), ...
        'LineWidth', 2.0, ...
        'DisplayName', D(i).label);
end

yline(0, 'k--', 'LineWidth', 1.0, 'DisplayName', 'Zero bias');

xlabel('Episode');
ylabel('Q0 bias = Q0 - Episode reward');
title(sprintf('Q0 Overestimation Bias, moving average window = %d', smoothWindow));
legend('Location', 'best');
set(gca, 'FontSize', 11);

outPng = fullfile(outDir, 'q0_bias_curve.png');
saveFigure(outPng);

%% ============================================================
% 5) Q0 bias boxplot
% ============================================================

allBias = [];
allGroup = [];
allLabel = {};

for i = 1:numAlg
    b = D(i).bias(:);
    b = b(~isnan(b));
    
    allBias = [allBias; b];
    allGroup = [allGroup; i * ones(numel(b), 1)];
end

figure('Name', 'Q0 Bias Boxplot', 'Color', 'w');
hold on; grid on; box on;

for i = 1:numAlg
    idx = allGroup == i;

    boxchart(allGroup(idx), allBias(idx), ...
        'BoxFaceColor', colors(i,:), ...
        'BoxFaceAlpha', 0.35, ...
        'MarkerStyle', 'o');
end

yline(0, 'k--', 'LineWidth', 1.0);

set(gca, 'XTick', 1:numAlg, 'XTickLabel', agentLabels);
ylabel('Q0 bias = Q0 - Episode reward');
title('Distribution of Q0 Bias');
set(gca, 'FontSize', 11);

outPng = fullfile(outDir, 'q0_bias_boxplot.png');
saveFigure(outPng);

%% ============================================================
% 6) Q0 bias 요약 통계 저장
% ============================================================

summaryTable = table();

for i = 1:numAlg
    b = D(i).bias(:);
    q0 = D(i).q0(:);
    rew = D(i).reward(:);

    tmp = table( ...
        {D(i).label}, ...
        numel(b), ...
        mean(q0, 'omitnan'), ...
        std(q0, 0, 'omitnan'), ...
        mean(rew, 'omitnan'), ...
        std(rew, 0, 'omitnan'), ...
        mean(b, 'omitnan'), ...
        std(b, 0, 'omitnan'), ...
        median(b, 'omitnan'), ...
        prctile(b, 25), ...
        prctile(b, 75), ...
        mean(b > 0, 'omitnan') * 100, ...
        'VariableNames', {'Algorithm','N', ...
        'Mean_Q0','Std_Q0', ...
        'Mean_Reward','Std_Reward', ...
        'Mean_Bias','Std_Bias', ...
        'Median_Bias','Q1_Bias','Q3_Bias', ...
        'Positive_Bias_Rate_Percent'});

    summaryTable = [summaryTable; tmp];
end

disp(' ');
disp('============================================================');
disp('Q0 Bias Summary');
disp('============================================================');
disp(summaryTable);

writetable(summaryTable, fullfile(outDir, 'q0_bias_summary.csv'));

%% ============================================================
% 7) 알고리즘 간 bias 차이 검정
% ============================================================

% Kruskal-Wallis: 세 알고리즘 이상의 bias 분포 차이
try
    [pKW, ~, statsKW] = kruskalwallis(allBias, allGroup, 'off');

    fprintf('\n============================================================\n');
    fprintf('Kruskal-Wallis test for Q0 bias among algorithms\n');
    fprintf('p = %.4e\n', pKW);
    fprintf('============================================================\n');

    % 다중 비교
    cmp = multcompare(statsKW, 'Display', 'off');

    cmpTable = array2table(cmp, ...
        'VariableNames', {'Group1','Group2','LowerCI','Difference','UpperCI','pValue'});

    % group number -> algorithm label 추가
    group1Label = cell(height(cmpTable), 1);
    group2Label = cell(height(cmpTable), 1);

    for r = 1:height(cmpTable)
        group1Label{r} = agentLabels{cmpTable.Group1(r)};
        group2Label{r} = agentLabels{cmpTable.Group2(r)};
    end

    cmpTable.Group1Label = group1Label;
    cmpTable.Group2Label = group2Label;

    disp(' ');
    disp('Pairwise multiple comparison of Q0 bias');
    disp(cmpTable);

    writetable(cmpTable, fullfile(outDir, 'q0_bias_pairwise_multcompare.csv'));

catch ME
    warning('Kruskal-Wallis 또는 multcompare 계산 실패: %s', ME.message);
end

%% ============================================================
% 8) Q0와 EpisodeReward 상관 분석
% ============================================================

corrTable = table();

for i = 1:numAlg
    q0 = D(i).q0(:);
    rew = D(i).reward(:);

    valid = ~isnan(q0) & ~isnan(rew);

    q0v = q0(valid);
    rewv = rew(valid);

    if numel(q0v) >= 3
        [rhoS, pS] = corr(q0v, rewv, ...
            'Type', 'Spearman', ...
            'Rows', 'complete');

        [rhoP, pP] = corr(q0v, rewv, ...
            'Type', 'Pearson', ...
            'Rows', 'complete');
    else
        rhoS = NaN; pS = NaN;
        rhoP = NaN; pP = NaN;
    end

    tmp = table( ...
        {D(i).label}, ...
        numel(q0v), ...
        rhoS, pS, rhoP, pP, ...
        'VariableNames', {'Algorithm','N', ...
        'Spearman_rho','Spearman_p', ...
        'Pearson_r','Pearson_p'});

    corrTable = [corrTable; tmp];
end

disp(' ');
disp('============================================================');
disp('Q0 vs Episode Reward Correlation');
disp('============================================================');
disp(corrTable);

writetable(corrTable, fullfile(outDir, 'q0_reward_correlation.csv'));

fprintf('\n완료.\n');
fprintf('결과 저장 폴더: %s\n', outDir);


%% =====================================================================
% Local functions
% =====================================================================

function v = readDatVector(path)
    M = readmatrix(path);

    % 전부 NaN인 행 제거
    M = M(~all(isnan(M), 2), :);

    if isempty(M)
        error('숫자 데이터를 읽지 못했습니다: %s', path);
    end

    % 데이터가 여러 열이면:
    % - 1열이 episode index이고 2열이 값인 형식일 수 있음
    % - 하지만 EpisodeIndex.dat는 1열일 가능성이 큼
    %
    % 여기서는 가장 안전하게:
    %   1열짜리면 그대로 사용
    %   2열 이상이면 마지막 열을 값으로 사용
    %
    % 예: [episode, reward] 형식이면 reward는 마지막 열
    if size(M, 2) == 1
        v = M(:, 1);
    else
        v = M(:, end);
    end

    v = v(:);
end


function saveFigure(outPng)
    try
        exportgraphics(gcf, outPng, 'Resolution', 300);
    catch
        saveas(gcf, outPng);
    end
end

function [q0Value, selectedCol] = readQ0ValueAuto(path)
    M = readmatrix(path);

    % 전부 NaN인 행 제거
    M = M(~all(isnan(M), 2), :);

    if isempty(M)
        error('Q0 파일에서 숫자 데이터를 읽지 못했습니다: %s', path);
    end

    nCol = size(M, 2);

    validCount = zeros(1, nCol);

    for j = 1:nCol
        col = M(:, j);
        validCount(j) = sum(~isnan(col));
    end

    % 전부 NaN인 열 제외
    candidateCols = find(validCount > 0);

    if isempty(candidateCols)
        error('Q0 파일에 유효한 숫자 열이 없습니다: %s', path);
    end

    % 유효값이 가장 많은 열을 Q0로 선택
    [~, idxMax] = max(validCount(candidateCols));
    selectedCol = candidateCols(idxMax);

    q0Value = M(:, selectedCol);
    q0Value = q0Value(:);

    fprintf('Q0 file: %s\n', path);
    fprintf('  selected Q0 column = %d\n', selectedCol);
    fprintf('  valid Q0 count = %d / %d\n', ...
        sum(~isnan(q0Value)), numel(q0Value));
end