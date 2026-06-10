%% statis2.m
% SAC vs No-Agent paired statistical analysis
% 현재 저장 구조:
% result/실험 결과 dat 파일 모음/fname/fname_all_runs.dat
% result/실험 결과 dat 파일 모음/fname/fname_seed_list.dat

clc; clear; close all;

%% ============================================================
% 0) 사용자 설정
% ============================================================

rootDir = "result";
datRoot = fullfile(rootDir, "실험 결과 dat 파일 모음");

% 비교 대상 이름
% 실제 폴더명 및 파일명과 완전히 같아야 함
fnameBase  = "No Agent(mod_2)";
fnameAgent = "(0.02)SAC_ver15(mod_1)";

labelBase  = "No Agent";
labelAgent = "SAC";

nBoot = 10000;
rngSeed = 0;
rng(rngSeed, 'twister');

% case 이름
caseNames = {'Hovering', 'Line', 'Circular', 'Figure-8'};

% 결과 저장 폴더
outDir = fullfile(rootDir, "paired_statistics_result");
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

%% ============================================================
% 1) 파일 경로 설정
% ============================================================

baseDatFile = fullfile(datRoot, fnameBase, ...
    fnameBase + "_all_runs.dat");

agentDatFile = fullfile(datRoot, fnameAgent, ...
    fnameAgent + "_all_runs.dat");

baseSeedFile = fullfile(datRoot, fnameBase, ...
    fnameBase + "_seed_list.dat");

agentSeedFile = fullfile(datRoot, fnameAgent, ...
    fnameAgent + "_seed_list.dat");

if ~isfile(baseDatFile)
    error('No Agent dat 파일을 찾을 수 없습니다:\n%s', baseDatFile);
end

if ~isfile(agentDatFile)
    error('Agent dat 파일을 찾을 수 없습니다:\n%s', agentDatFile);
end

fprintf('Base dat file:\n%s\n\n', baseDatFile);
fprintf('Agent dat file:\n%s\n\n', agentDatFile);

%% ============================================================
% 2) seed list 확인
% ============================================================

if isfile(baseSeedFile) && isfile(agentSeedFile)
    baseSeed = readmatrix(baseSeedFile);
    agentSeed = readmatrix(agentSeedFile);

    if size(baseSeed,2) >= 2 && size(agentSeed,2) >= 2
        if isequal(baseSeed(:,2), agentSeed(:,2))
            fprintf('Seed list 일치: paired analysis 전제 만족\n\n');
        else
            warning('Seed list가 일치하지 않습니다. paired analysis 전제를 다시 확인해야 합니다.');
        end
    else
        warning('seed_list.dat 열 구조가 예상과 다릅니다. seed 일치 여부를 확인하지 못했습니다.');
    end
else
    warning('seed_list.dat 파일 중 하나를 찾지 못했습니다. seed 일치 여부는 확인하지 않습니다.');
end

%% ============================================================
% 3) dat 파일 로드
% ============================================================

baseRaw  = loadDatFile(baseDatFile);
agentRaw = loadDatFile(agentDatFile);

%% ============================================================
% 4) run/case별 RMSE 계산
% ============================================================

baseRmse  = computePerRunRmse(baseRaw);
agentRmse = computePerRunRmse(agentRaw);

%% ============================================================
% 5) Position RMSE paired analysis
% ============================================================

fprintf('======================================================================\n');
fprintf('  3D POSITION RMSE\n');
fprintf('======================================================================\n');

[posResult, mergedPos] = analyzePairedRmse( ...
    baseRmse, agentRmse, 'pos_rmse', caseNames, nBoot);

disp(posResult);

posCsv = fullfile(outDir, 'stats_pos_rmse.csv');
writetable(posResult, posCsv);

[rho, pval, outPng] = correlationAnalysis( ...
    mergedPos, 'pos_rmse', caseNames, outDir, labelBase, labelAgent);

fprintf('\n[보정 여지 가설] baseline RMSE vs 절대 감소량:\n');
fprintf('  Spearman rho = %.4f, p = %.4e, n = %d\n', ...
    rho, pval, height(mergedPos));
fprintf('  산점도 저장: %s\n\n', outPng);

%% ============================================================
% 6) Velocity RMSE paired analysis
% ============================================================

fprintf('======================================================================\n');
fprintf('  3D VELOCITY RMSE\n');
fprintf('======================================================================\n');

[velResult, mergedVel] = analyzePairedRmse( ...
    baseRmse, agentRmse, 'vel_rmse', caseNames, nBoot);

disp(velResult);

velCsv = fullfile(outDir, 'stats_vel_rmse.csv');
writetable(velResult, velCsv);

fprintf('\nCSV/PNG 저장 완료.\n');
fprintf('결과 폴더: %s\n', outDir);


%% =====================================================================
% Local functions
% =====================================================================

function T = loadDatFile(path)
    % .dat 파일 로드
    % 저장 코드 기준 열 순서:
    % 1 run
    % 2 case_Num
    % 3 t
    % 4 x
    % 5 y
    % 6 z
    % 7 e_v_dir
    % 8 e_v_mag
    % 9 phi
    % 10 theta
    % 11 psi
    % 12 p
    % 13 q
    % 14 r
    % 15:18 Agent_Th1~4
    % 19:22 Total_Th1~4
    % 23 x_pos
    % 24 y_pos
    % 25 z_pos
    % 26 x_vel
    % 27 y_vel
    % 28 z_vel
    % 29 x_vel_cmd
    % 30 y_vel_cmd
    % 31 z_vel_cmd

    colNames = {'run','case','t','x','y','z','e_v_dir','e_v_mag', ...
        'phi','theta','psi','p','q','r', ...
        'Ag1','Ag2','Ag3','Ag4', ...
        'Tt1','Tt2','Tt3','Tt4', ...
        'x_pos','y_pos','z_pos', ...
        'x_vel','y_vel','z_vel', ...
        'x_vel_cmd','y_vel_cmd','z_vel_cmd'};

    M = readmatrix(path);

    % 전부 NaN인 행 제거
    M = M(~all(isnan(M), 2), :);

    % 혹시 헤더가 숫자로 읽혀 NaN 행이 섞인 경우 대비
    if isempty(M)
        error('파일에서 숫자 데이터를 읽지 못했습니다:\n%s', path);
    end

    if size(M, 2) ~= numel(colNames)
        error('열 개수가 맞지 않습니다. 읽은 열 수 = %d, 기대 열 수 = %d\n파일: %s', ...
            size(M, 2), numel(colNames), path);
    end

    T = array2table(M, 'VariableNames', colNames);

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
    %   기존 total_statistical_revised.m과 맞추기 위해 e_v_mag 사용
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
            % 단측 sign test
            % P[X >= nWins], X ~ Binomial(n, 0.5)
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


function [rho, pval, outPng] = correlationAnalysis(M, metricName, caseNames, outDir, labelBase, labelAgent)
    % baseline RMSE vs absolute reduction
    % metricName은 파일명/제목용으로만 사용

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

    yline(0, 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8, ...
        'DisplayName', 'No reduction');

    xlabel(sprintf('Baseline (%s) 3D position RMSE [m]', labelBase));
    ylabel(sprintf('Absolute RMSE reduction by %s [m]', labelAgent));

    title(sprintf('Reduction vs baseline error  (Spearman rho = %.3f, p = %.2e)', ...
        rho, pval));

    legend('Location', 'best');
    set(gca, 'FontSize', 11);

    outPng = fullfile(outDir, ['reduction_vs_baseline_' metricName '.png']);

    try
        exportgraphics(gcf, outPng, 'Resolution', 300);
    catch
        saveas(gcf, outPng);
    end

    close(gcf);
end