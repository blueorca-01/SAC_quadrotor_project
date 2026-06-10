%% statis_multi_agents.m
% Paired statistical analysis for multiple control agents
%
% 이 스크립트는 기준 baseline인 "No Agent"와 여러 강화학습 기반
% 에이전트(DDPG, TD3, SAC)를 비교하여 각 실험 케이스별로
% paired 통계 분석을 수행합니다.
%
% 주요 역할:
%  1) baseline 및 비교할 agent들의 결과 데이터를 로드
%  2) 각 케이스별 RMSE를 계산하여 paired 통계 검정 수행
%  3) 분석 결과를 지정된 출력 폴더에 저장
%
% 데이터 경로 구조:
% result/실험 결과 dat 파일 모음/fname/fname_all_runs.dat
% result/실험 결과 dat 파일 모음/fname/fname_seed_list.dat

clc; clear; close all;

%% ============================================================
% 0) 사용자 설정
% ============================================================

rootDir = 'result';
datRoot = fullfile(rootDir, '실험 결과 dat 파일 모음');

% 기준 baseline
baseName  = 'No Agent(mod_2)';
baseLabel = 'No Agent';

% 비교할 알고리즘 목록
% 반드시 실제 폴더명과 정확히 일치해야 함
% agentNames = { ...
%     "(0.02)DDPG_ver4(mod_1)"
%     "(0.02)TD3_ver3(mod_1)"
%     "(0.02)SAC_ver15(mod_1)"
% };

agentLabels = { ...
    'DDPG', ...
    'TD3', ...
    'SAC' ...
};

% 만약 실제 파일명이 아래라면 위 agentNames를 이렇게 바꿔야 함
agentNames = { ...
    '(0.02)DDPG_ver4(mod_1)', ...
    '(0.015)TD3_ver3(mod_1)', ...
    '(0.02)SAC_ver15(mod_1)' ...
};

nBoot = 10000;
rngSeed = 0;
rng(rngSeed, 'twister');

caseNames = {'Hovering', 'Line', 'Circular', 'Figure-8'};

outDir = fullfile(rootDir, 'paired_statistics_result_multi');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

%% ============================================================
% 1) Baseline 로드
% ============================================================

baseDatFile = makeDatPath(datRoot, baseName);
baseSeedFile = makeSeedPath(datRoot, baseName);

if ~isfile(baseDatFile)
    error('Baseline dat 파일을 찾을 수 없습니다:\n%s', baseDatFile);
end

fprintf('======================================================================\n');
fprintf('Baseline: %s\n', baseName);
fprintf('Baseline dat file:\n%s\n', baseDatFile);
fprintf('======================================================================\n\n');

baseRaw = loadDatFile(baseDatFile);
baseRmse = computePerRunRmse(baseRaw);

%% ============================================================
% 2) 각 Agent별 paired analysis
% ============================================================

allPosResult = table();
allVelResult = table();

for a = 1:numel(agentNames)

    agentName = agentNames{a};
    agentLabel = agentLabels{a};

    agentDatFile = makeDatPath(datRoot, agentName);
    agentSeedFile = makeSeedPath(datRoot, agentName);

    fprintf('\n\n######################################################################\n');
    fprintf('Comparing: %s vs %s\n', baseLabel, agentLabel);
    fprintf('Agent name: %s\n', agentName);
    fprintf('######################################################################\n');

    if ~isfile(agentDatFile)
        warning('Agent dat 파일이 없습니다. 건너뜁니다:\n%s', agentDatFile);
        continue;
    end

    fprintf('Agent dat file:\n%s\n\n', agentDatFile);

    % seed list 확인
    checkSeedList(baseSeedFile, agentSeedFile, baseLabel, agentLabel);

    % Agent 데이터 로드
    agentRaw = loadDatFile(agentDatFile);
    agentRmse = computePerRunRmse(agentRaw);

    %% Position RMSE
    fprintf('======================================================================\n');
    fprintf('  3D POSITION RMSE: %s vs %s\n', baseLabel, agentLabel);
    fprintf('======================================================================\n');

    [posResult, mergedPos] = analyzePairedRmse( ...
        baseRmse, agentRmse, 'pos_rmse', caseNames, nBoot);

    posResult = addAlgorithmColumn(posResult, agentLabel);
    disp(posResult);

    posCsv = fullfile(outDir, ['stats_pos_rmse_' makeSafeName(agentLabel) '.csv']);
    writetable(posResult, posCsv);

    [rho, pval, outPng] = correlationAnalysis( ...
        mergedPos, 'pos_rmse', caseNames, outDir, baseLabel, agentLabel);

    fprintf('\n[보정 여지 가설: %s] baseline RMSE vs 절대 감소량:\n', agentLabel);
    fprintf('  Spearman rho = %.4f, p = %.4e, n = %d\n', ...
        rho, pval, height(mergedPos));
    fprintf('  산점도 저장: %s\n\n', outPng);

    decompPos = correlationDecomposition(mergedPos, agentLabel);

    decompCsv = fullfile(outDir, ...
        ['corr_decomposition_pos_rmse_' makeSafeName(agentLabel) '.csv']);
    
    writetable(decompPos, decompCsv);

    %% Velocity RMSE
    fprintf('======================================================================\n');
    fprintf('  3D VELOCITY RMSE: %s vs %s\n', baseLabel, agentLabel);
    fprintf('======================================================================\n');

    [velResult, mergedVel] = analyzePairedRmse( ...
        baseRmse, agentRmse, 'vel_rmse', caseNames, nBoot);

    velResult = addAlgorithmColumn(velResult, agentLabel);
    disp(velResult);

    velCsv = fullfile(outDir, ['stats_vel_rmse_' makeSafeName(agentLabel) '.csv']);
    writetable(velResult, velCsv);

    %% 통합 결과 누적
    allPosResult = [allPosResult; posResult];
    allVelResult = [allVelResult; velResult];
end

%% ============================================================
% 3) 전체 통합 결과 저장
% ============================================================

if ~isempty(allPosResult)
    allPosResult.GlobalHolm_p = holmCorrection(allPosResult.Wilcox_p);
    writetable(allPosResult, fullfile(outDir, 'ALL_stats_pos_rmse.csv'));
end

if ~isempty(allVelResult)
    allVelResult.GlobalHolm_p = holmCorrection(allVelResult.Wilcox_p);
    writetable(allVelResult, fullfile(outDir, 'ALL_stats_vel_rmse.csv'));
end

fprintf('\n\n======================================================================\n');
fprintf('모든 paired analysis 완료.\n');
fprintf('결과 폴더: %s\n', outDir);
fprintf('======================================================================\n');


%% =====================================================================
% Local functions
% =====================================================================

function file = makeDatPath(datRoot, fname)
    datRoot = char(datRoot);
    fname = char(fname);

    file = fullfile(datRoot, fname, [fname '_all_runs.dat']);
end


function file = makeSeedPath(datRoot, fname)
    datRoot = char(datRoot);
    fname = char(fname);

    file = fullfile(datRoot, fname, [fname '_seed_list.dat']);
end


function safe = makeSafeName(name)
    name = char(name);
    safe = regexprep(name, '[^\w가-힣]', '_');
end


function checkSeedList(baseSeedFile, agentSeedFile, baseLabel, agentLabel)

    if ~isfile(baseSeedFile)
        warning('%s seed file이 없습니다:\n%s', baseLabel, baseSeedFile);
        return;
    end

    if ~isfile(agentSeedFile)
        warning('%s seed file이 없습니다:\n%s', agentLabel, agentSeedFile);
        return;
    end

    baseSeed = readmatrix(baseSeedFile);
    agentSeed = readmatrix(agentSeedFile);

    if size(baseSeed,2) < 2 || size(agentSeed,2) < 2
        warning('seed_list.dat 열 구조가 예상과 다릅니다. seed 일치 여부를 확인하지 못했습니다.');
        return;
    end

    if size(baseSeed,1) ~= size(agentSeed,1)
        warning('%s와 %s의 seed 개수가 다릅니다. paired analysis 전제를 확인해야 합니다.', ...
            baseLabel, agentLabel);
        return;
    end

    if isequal(baseSeed(:,2), agentSeed(:,2))
        fprintf('Seed list 일치: %s vs %s paired analysis 전제 만족\n\n', ...
            baseLabel, agentLabel);
    else
        warning('Seed list 불일치: %s vs %s paired analysis 전제를 다시 확인해야 합니다.', ...
            baseLabel, agentLabel);
    end
end


function T = loadDatFile(path)
    % .dat 파일 로드
    % 25열 구버전과 31열 신버전을 모두 허용
    %
    % 25열:
    %   run, case, t, x, y, z, e_v_dir, e_v_mag,
    %   phi, theta, psi, p, q, r,
    %   Agent_Th1~4, Total_Th1~4,
    %   x_pos, y_pos, z_pos
    %
    % 31열:
    %   25열 + x_vel, y_vel, z_vel, x_vel_cmd, y_vel_cmd, z_vel_cmd

    colNames31 = {'run','case','t','x','y','z','e_v_dir','e_v_mag', ...
        'phi','theta','psi','p','q','r', ...
        'Ag1','Ag2','Ag3','Ag4', ...
        'Tt1','Tt2','Tt3','Tt4', ...
        'x_pos','y_pos','z_pos', ...
        'x_vel','y_vel','z_vel', ...
        'x_vel_cmd','y_vel_cmd','z_vel_cmd'};

    M = readmatrix(path);

    % 전부 NaN인 행 제거
    M = M(~all(isnan(M), 2), :);

    if isempty(M)
        error('파일에서 숫자 데이터를 읽지 못했습니다:\n%s', path);
    end

    nCol = size(M, 2);

    if nCol == 25
        % 구버전: 속도 실제값/명령값 6개 열이 없음
        M = [M, nan(size(M,1), 6)];
        fprintf('구버전 25열 dat 감지: 속도 실제값/명령값 6개 열을 NaN으로 채움\n');
        fprintf('파일: %s\n\n', path);

    elseif nCol == 31
        % 신버전: 그대로 사용
        % 아무 처리 필요 없음

    else
        error('지원하지 않는 열 개수입니다. 읽은 열 수 = %d, 지원 열 수 = 25 또는 31\n파일: %s', ...
            nCol, path);
    end

    T = array2table(M, 'VariableNames', colNames31);

    T.run  = round(T.run);
    T.case = round(T.case);

    validIdx = ~isnan(T.run) & ~isnan(T.case) & ~isnan(T.t);
    T = T(validIdx, :);
end


function R = computePerRunRmse(T)
    % case/run별 RMSE 계산
    %
    % pos_rmse:
    %   sqrt(mean(x^2 + y^2 + z^2))
    %
    % vel_rmse:
    %   e_v_mag 기준
    %   sqrt(mean(e_v_mag^2))

    [G, caseVals, runVals] = findgroups(T.case, T.run);

    posRmse = splitapply(@localPosRmse, T.x, T.y, T.z, G);
    velRmse = splitapply(@localScalarRmse, T.e_v_mag, G);

    R = table(caseVals(:), runVals(:), posRmse(:), velRmse(:), ...
        'VariableNames', {'case','run','pos_rmse','vel_rmse'});
end


function y = localPosRmse(x, yv, z)
    e2 = x.^2 + yv.^2 + z.^2;
    y = sqrt(meanOmitNaN(e2));
end


function y = localScalarRmse(e)
    y = sqrt(meanOmitNaN(e.^2));
end


function m = meanOmitNaN(x)
    x = x(~isnan(x));
    if isempty(x)
        m = NaN;
    else
        m = mean(x);
    end
end


function resultTable = addAlgorithmColumn(resultTable, agentLabel)
    alg = repmat({agentLabel}, height(resultTable), 1);
    algTable = table(alg, 'VariableNames', {'Algorithm'});
    resultTable = [algTable resultTable];
end


function [resultTable, M] = analyzePairedRmse(baseRmse, agentRmse, metricName, caseNames, nBoot)
    % baseRmse와 agentRmse를 같은 case/run 기준으로 inner join
    % metricName: 'pos_rmse' 또는 'vel_rmse'

    baseTmp = baseRmse(:, {'case','run',metricName});
    agentTmp = agentRmse(:, {'case','run',metricName});

    baseTmp.Properties.VariableNames = {'case','run','base'};
    agentTmp.Properties.VariableNames = {'case','run','agent'};

    M = innerjoin(baseTmp, agentTmp, 'Keys', {'case','run'});

    cases = unique(M.case);
    cases = sort(cases(:));

    nCase = numel(cases);

    Case = cell(nCase, 1);
    NoAgent = nan(nCase, 1);
    Agent = nan(nCase, 1);
    ImprPercent = nan(nCase, 1);
    CI_lo = nan(nCase, 1);
    CI_hi = nan(nCase, 1);
    Wilcox_p = nan(nCase, 1);
    Holm_p = nan(nCase, 1);
    effect_r = nan(nCase, 1);
    wins = cell(nCase, 1);
    sign_p = nan(nCase, 1);
    nPair = nan(nCase, 1);

    for i = 1:nCase
        c = cases(i);
        idx = M.case == c;

        base = M.base(idx);
        agent = M.agent(idx);

        valid = ~isnan(base) & ~isnan(agent);
        base = base(valid);
        agent = agent(valid);

        d = base - agent;   % 양수면 Agent가 더 좋음

        meanBase = meanOmitNaN(base);
        meanAgent = meanOmitNaN(agent);

        impr = (meanBase - meanAgent) / meanBase * 100;

        % Wilcoxon signed-rank test
        % H1: median(base - agent) > 0
        % 즉, Agent RMSE가 Base보다 작다는 단측 검정
        if numel(d) > 0 && any(d ~= 0)
            try
                pWilcox = signrank(base, agent, 'tail', 'right');
            catch
                pWilcox = NaN;
                warning('signrank 계산 실패: Case %d', c);
            end
        else
            pWilcox = NaN;
        end

        rb = rankBiserialFromDiff(d);

        [lo, hi] = bootstrapImprovementCi(base, agent, nBoot);

        n = numel(d);
        nWins = sum(d > 0);

        if n > 0
            pSign = 1 - binocdf(nWins - 1, n, 0.5);
        else
            pSign = NaN;
        end

        if c >= 1 && c <= numel(caseNames)
            Case{i} = caseNames{c};
        else
            Case{i} = sprintf('Case %d', c);
        end

        NoAgent(i) = meanBase;
        Agent(i) = meanAgent;
        ImprPercent(i) = impr;
        CI_lo(i) = lo;
        CI_hi(i) = hi;
        Wilcox_p(i) = pWilcox;
        effect_r(i) = rb;
        wins{i} = sprintf('%d/%d', nWins, n);
        sign_p(i) = pSign;
        nPair(i) = n;
    end

    Holm_p = holmCorrection(Wilcox_p);

    resultTable = table(Case(:), NoAgent(:), Agent(:), ImprPercent(:), ...
        CI_lo(:), CI_hi(:), Wilcox_p(:), Holm_p(:), effect_r(:), ...
        wins(:), sign_p(:), nPair(:), ...
        'VariableNames', {'Case','NoAgent','Agent','ImprPercent', ...
        'CI_lo','CI_hi','Wilcox_p','Holm_p','effect_r', ...
        'wins','sign_p','nPair'});
end


function rb = rankBiserialFromDiff(d)
    % paired rank-biserial effect size
    % d = base - agent
    % 양수면 Agent 우세

    d = d(~isnan(d));
    d = d(d ~= 0);

    if isempty(d)
        rb = NaN;
        return;
    end

    r = tiedrank(abs(d));

    Rpos = sum(r(d > 0));
    Rneg = sum(r(d < 0));
    T = Rpos + Rneg;

    rb = (Rpos - Rneg) / T;
end


function [lo, hi] = bootstrapImprovementCi(base, agent, nBoot)
    % paired bootstrap CI
    % improvement = (mean(base)-mean(agent))/mean(base)*100

    valid = ~isnan(base) & ~isnan(agent);
    base = base(valid);
    agent = agent(valid);

    n = numel(base);

    if n == 0
        lo = NaN;
        hi = NaN;
        return;
    end

    impr = nan(nBoot, 1);

    for k = 1:nBoot
        idx = randi(n, n, 1);
        bb = mean(base(idx));
        aa = mean(agent(idx));
        impr(k) = (bb - aa) / bb * 100;
    end

    ci = prctile(impr, [2.5, 97.5]);
    lo = ci(1);
    hi = ci(2);
end


function adjP = holmCorrection(pvals)
    % Holm-Bonferroni correction
    % NaN은 NaN으로 유지

    pvals = pvals(:);
    adjP = nan(size(pvals));

    validIdx = find(~isnan(pvals));
    p = pvals(validIdx);

    m = numel(p);

    if m == 0
        return;
    end

    [sortedP, order] = sort(p);
    adjSorted = nan(m, 1);

    running = 0;

    for k = 1:m
        val = (m - k + 1) * sortedP(k);
        running = max(running, val);
        adjSorted(k) = min(running, 1);
    end

    tmp = nan(m, 1);
    tmp(order) = adjSorted;

    adjP(validIdx) = tmp;
end


function [rho, pval, outPng] = correlationAnalysis(M, metricName, caseNames, outDir, labelBase, agentLabel)
    % baseline RMSE vs absolute reduction
    % metricName은 파일명/제목용으로 사용

    base = M.base;
    agent = M.agent;
    reduction = base - agent;

    valid = ~isnan(base) & ~isnan(reduction);
    baseValid = base(valid);
    reductionValid = reduction(valid);

    if numel(baseValid) >= 2
        [rho, pval] = corr(baseValid, reductionValid, ...
            'Type', 'Spearman', 'Rows', 'complete');
    else
        rho = NaN;
        pval = NaN;
    end

    figure('Color', 'w');
    hold on; grid on; box on;

    colors = [ ...
        0.0000 0.4470 0.7410; ...
        0.4660 0.6740 0.1880; ...
        0.8500 0.3250 0.0980; ...
        0.4940 0.1840 0.5560];

    cases = unique(M.case);
    cases = sort(cases(:));

    for i = 1:numel(cases)
        c = cases(i);
        idx = M.case == c;

        if c >= 1 && c <= numel(caseNames)
            label = sprintf('Case %d (%s)', c, caseNames{c});
        else
            label = sprintf('Case %d', c);
        end

        colorIdx = mod(i-1, size(colors,1)) + 1;

        scatter(base(idx), reduction(idx), 42, ...
            'filled', ...
            'MarkerFaceColor', colors(colorIdx,:), ...
            'MarkerEdgeColor', [1 1 1], ...
            'DisplayName', label);
    end

    % 추세선
    if numel(baseValid) >= 2
        coeff = polyfit(baseValid, reductionValid, 1);
        xs = linspace(min(baseValid), max(baseValid), 100);
        ys = polyval(coeff, xs);
        plot(xs, ys, 'k--', 'LineWidth', 1.2, ...
            'DisplayName', 'Linear trend');
    end

    % y = 0 기준선
    xl = xlim;
    plot(xl, [0 0], '-', 'Color', [0.5 0.5 0.5], ...
        'LineWidth', 0.8, 'DisplayName', 'No reduction');

    xlabel(sprintf('Baseline (%s) 3D position RMSE [m]', labelBase));
    ylabel(sprintf('Absolute RMSE reduction by %s [m]', agentLabel));

    title(sprintf('%s: Reduction vs baseline error  (Spearman rho = %.3f, p = %.2e)', ...
        agentLabel, rho, pval));

    legend('Location', 'best');
    set(gca, 'FontSize', 11);

    outPng = fullfile(outDir, ...
        ['reduction_vs_baseline_' makeSafeName(agentLabel) '_' metricName '.png']);

    try
        exportgraphics(gcf, outPng, 'Resolution', 300);
    catch
        saveas(gcf, outPng);
    end

    close(gcf);
end


function decompTable = correlationDecomposition(M, agentLabel)
    % within-case vs between-case correlation decomposition
    %
    % 입력 M:
    %   M.case
    %   M.run
    %   M.base
    %   M.agent
    %
    % reduction = base - agent
    % 양수면 agent가 No Agent보다 RMSE를 줄인 것

    base = M.base;
    agent = M.agent;
    reduction = base - agent;

    valid = ~isnan(base) & ~isnan(reduction);
    base = base(valid);
    reduction = reduction(valid);
    caseVec = M.case(valid);

    % 1) pooled correlation
    if numel(base) >= 2
        [rhoPooled, pPooled] = corr(base, reduction, ...
            'Type', 'Spearman', 'Rows', 'complete');
    else
        rhoPooled = NaN;
        pPooled = NaN;
    end

    % 2) within-case correlation
    cases = unique(caseVec);
    cases = sort(cases(:));

    nCase = numel(cases);

    caseOut = nan(nCase, 1);
    rhoWithin = nan(nCase, 1);
    pWithin = nan(nCase, 1);
    nWithin = nan(nCase, 1);

    zList = [];
    wList = [];

    for i = 1:nCase
        c = cases(i);
        idx = caseVec == c;

        b = base(idx);
        r = reduction(idx);

        caseOut(i) = c;
        nWithin(i) = numel(b);

        if numel(b) >= 3 && numel(unique(b)) >= 2 && numel(unique(r)) >= 2
            [rhoC, pC] = corr(b, r, ...
                'Type', 'Spearman', 'Rows', 'complete');

            rhoWithin(i) = rhoC;
            pWithin(i) = pC;

            % Fisher z 평균용
            if isfinite(rhoC) && abs(rhoC) < 0.9999
                zList(end+1, 1) = atanh(rhoC); %#ok<AGROW>
                wList(end+1, 1) = numel(b) - 3; %#ok<AGROW>
            end
        end
    end

    if ~isempty(zList)
        zMean = sum(zList .* wList) / sum(wList);
        rhoWithinMean = tanh(zMean);
    else
        rhoWithinMean = NaN;
    end

    % 3) between-case correlation
    baseMean = nan(nCase, 1);
    reductionMean = nan(nCase, 1);

    for i = 1:nCase
        c = cases(i);
        idx = caseVec == c;

        baseMean(i) = mean(base(idx), 'omitnan');
        reductionMean(i) = mean(reduction(idx), 'omitnan');
    end

    if nCase >= 3 && numel(unique(baseMean)) >= 2 && numel(unique(reductionMean)) >= 2
        [rhoBetween, pBetween] = corr(baseMean, reductionMean, ...
            'Type', 'Spearman', 'Rows', 'complete');
    else
        rhoBetween = NaN;
        pBetween = NaN;
    end

    % 출력
    fprintf('\n========== %s : reduction vs baseline 상관 분해 ==========\n', agentLabel);
    fprintf('[pooled  n=%d] Spearman rho = %+0.3f  (p = %.2e)\n', ...
        numel(base), rhoPooled, pPooled);
    fprintf('[between n=%d] Spearman rho = %+0.3f  (p = %.2e)\n', ...
        nCase, rhoBetween, pBetween);
    fprintf('[within 평균] Spearman rho = %+0.3f  (Fisher-z, 표본수 가중)\n', ...
        rhoWithinMean);

    fprintf('케이스별 within:\n');
    for i = 1:nCase
        if isfinite(pWithin(i)) && pWithin(i) < 0.05
            flag = '';
        else
            flag = '  (n.s.)';
        end

        fprintf('  Case %d: rho = %+0.3f, p = %.3f, n = %d%s\n', ...
            caseOut(i), rhoWithin(i), pWithin(i), nWithin(i), flag);
    end

    Algorithm = repmat({agentLabel}, nCase, 1);
    Case = caseOut;
    Within_rho = rhoWithin;
    Within_p = pWithin;
    Within_n = nWithin;

    decompTable = table(Algorithm, Case, Within_rho, Within_p, Within_n, ...
        'VariableNames', {'Algorithm','Case','Within_rho','Within_p','Within_n'});

    % summary 값은 UserData에 저장
    decompTable.Properties.UserData.Pooled_rho = rhoPooled;
    decompTable.Properties.UserData.Pooled_p = pPooled;
    decompTable.Properties.UserData.Between_rho = rhoBetween;
    decompTable.Properties.UserData.Between_p = pBetween;
    decompTable.Properties.UserData.Within_mean_rho = rhoWithinMean;
end