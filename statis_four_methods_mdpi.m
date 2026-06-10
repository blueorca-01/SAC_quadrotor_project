%% statis_four_methods_mdpi.m
% MDPI 논문 작성용 4개 제어 방법 paired 통계 분석 코드.
%
% 해석 시 주의사항:
% - 동일한 seed/run 구조를 사용하므로 반복측정 설계(repeated-measures design)로 간주한다.
%   따라서 Friedman 검정과 paired Wilcoxon signed-rank 검정을 사용한다.
% - RMSE 분포가 정규분포를 따른다고 가정하지 않기 위해 비모수 검정을 사용한다.
% - p-value만 단독으로 해석하지 말고, 개선율, 신뢰구간, 효과크기를 함께 고려해야 한다.
clc; clear; close all;

%% ============================================================
% 0) User settings
% ============================================================

rootDir = "result";
datRoot = fullfile(rootDir, "실험 결과 dat 파일 모음");
outDir = fullfile(rootDir, "four_method_statistics_result");

methodLabels = ["No Agent", "DDPG", "TD3", "SAC"];

% Keep the real folder/file names here so they are easy to edit.
fnameList = [
    "No Agent(mod_1)"
    "(Huber)(0.02)DDPG_ver1(mod_1)"
    "(Huber)TD3_ver1(mod_1)"
    "(cpu2)(Huber)(0.02)SAC_ver4(mod_1)"
];

safeMethodNames = {'NoAgent', 'DDPG', 'TD3', 'SAC'};
caseNames = {'Hovering', 'Line', 'Circular', 'Figure-8'};

nBoot = 10000;
rngSeed = 0;
rng(rngSeed, 'twister');

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

datRoot = resolveDatRoot(rootDir, datRoot, fnameList);

fprintf('======================================================================\n');
fprintf('Four-method paired RMSE statistics\n');
fprintf('Data root: %s\n', datRoot);
fprintf('Output dir: %s\n', outDir);
fprintf('======================================================================\n\n');

%% ============================================================
% 1) File paths, seed checks, and per-run RMSE
% ============================================================

nMethod = numel(methodLabels);
rmseTables = cell(nMethod, 1);
seedTables = cell(nMethod, 1);
pairCounts = nan(nMethod, 1);

for m = 1:nMethod
    label = char(methodLabels(m));
    fname = char(fnameList(m));

    datFile = makeDatPath(datRoot, fname);
    seedFile = makeSeedPath(datRoot, fname);

    fprintf('[%s]\n', label);
    fprintf('  dat : %s\n', datFile);
    fprintf('  seed: %s\n', seedFile);

    if ~isfile(datFile)
        error('Required dat file was not found for %s:\n%s', label, datFile);
    end
    if ~isfile(seedFile)
        warning('seed_list.dat was not found for %s:\n%s', label, seedFile);
        seedTables{m} = [];
    else
        seedTables{m} = readmatrix(seedFile);
    end

    rawTable = loadDatFile(datFile);
    rmseTables{m} = computePerRunRmse(rawTable);
    pairCounts(m) = height(rmseTables{m});

    fprintf('  per-run pairs: %d\n\n', pairCounts(m));
end

checkAllSeedLists(seedTables, methodLabels);

if numel(unique(pairCounts(~isnan(pairCounts)))) > 1
    error('Different numbers of case/run RMSE pairs were found across methods: %s', ...
        mat2str(pairCounts(:)'));
end

%% ============================================================
% 2) Long and wide tables
% ============================================================

longTable = buildLongTable(rmseTables, methodLabels);
wideTable = buildWideTable(rmseTables, safeMethodNames);

allPairs = unique(longTable(:, {'case', 'run'}), 'rows');
fprintf('Inner join retained %d common case/run pairs out of %d unique pairs.\n\n', ...
    height(wideTable), height(allPairs));

writetable(longTable, fullfile(outDir, 'long_pos_rmse_by_method.csv'));
writetable(wideTable, fullfile(outDir, 'wide_pos_rmse_by_case_run.csv'));

fprintf('Long table preview:\n');
disp(headRows(longTable, 12));
fprintf('Wide table preview:\n');
disp(headRows(wideTable, 12));

%% ============================================================
% 3) Case-wise Friedman tests
% ============================================================

friedmanTable = runCasewiseFriedman(wideTable, safeMethodNames, caseNames);
fprintf('\nFriedman test results for 3D position RMSE:\n');
writetable(friedmanTable, fullfile(outDir, 'stats_friedman_pos_rmse.csv'));
fprintf('  Full table saved to stats_friedman_pos_rmse.csv\n');

%% ============================================================
% 4) SAC-centered post-hoc paired comparisons
% ============================================================

posthocTable = runSacPosthoc(wideTable, safeMethodNames, caseNames, nBoot);
fprintf('\nSAC-centered post-hoc paired comparisons:\n');
writetable(posthocTable, fullfile(outDir, 'stats_sac_posthoc_pos_rmse.csv'));
fprintf('  Full table saved to stats_sac_posthoc_pos_rmse.csv\n');

manuscriptMeanTable = makeManuscriptMeanTable(friedmanTable);
manuscriptSacVsNoAgent = makeManuscriptPairwiseTable(posthocTable, 'SAC vs NoAgent');
manuscriptSacVsDDPG = makeManuscriptPairwiseTable(posthocTable, 'SAC vs DDPG');
manuscriptSacVsTD3 = makeManuscriptPairwiseTable(posthocTable, 'SAC vs TD3');
manuscriptPosthocCompactTable = makeManuscriptPosthocCompactTable(posthocTable);

writetable(manuscriptMeanTable, fullfile(outDir, 'manuscript_table_mean_rmse.csv'));
writetable(manuscriptSacVsNoAgent, fullfile(outDir, 'manuscript_table_sac_vs_noagent.csv'));
writetable(manuscriptSacVsDDPG, fullfile(outDir, 'manuscript_table_sac_vs_ddpg.csv'));
writetable(manuscriptSacVsTD3, fullfile(outDir, 'manuscript_table_sac_vs_td3.csv'));
writetable(manuscriptPosthocCompactTable, fullfile(outDir, 'manuscript_table_sac_posthoc_compact.csv'));

%% ============================================================
% 5) Figures
% ============================================================

makeBoxplotByCase(longTable, methodLabels, caseNames, outDir);
makeImprovementBarPlot(posthocTable, caseNames, outDir);
correlationAnalysisSacNoAgent(wideTable, caseNames, outDir);

%% ============================================================
% 6) Console summary for manuscript drafting
% ============================================================

printConsoleSummary(friedmanTable, posthocTable, wideTable, safeMethodNames, methodLabels);

disp("Manuscript Table A: Mean 3D position RMSE and Friedman test");
disp(manuscriptMeanTable);

disp("Manuscript Table B: SAC vs No Agent");
disp(manuscriptSacVsNoAgent);

disp("Manuscript Table C: SAC vs DDPG");
disp(manuscriptSacVsDDPG);

disp("Manuscript Table D: SAC vs TD3");
disp(manuscriptSacVsTD3);

fprintf('\nAll CSV/PNG outputs were saved in:\n%s\n', outDir);

%% =====================================================================
% Local functions
% =====================================================================

function datRoot = resolveDatRoot(rootDir, preferredRoot, fnameList)
    datRoot = char(preferredRoot);
    if isfolder(datRoot)
        return;
    end

    rootDir = char(rootDir);
    d = dir(rootDir);
    bestRoot = '';
    for i = 1:numel(d)
        if ~d(i).isdir || strcmp(d(i).name, '.') || strcmp(d(i).name, '..')
            continue;
        end
        candidate = fullfile(rootDir, d(i).name);
        firstMethodDir = fullfile(candidate, char(fnameList(1)));
        if isfolder(firstMethodDir)
            bestRoot = candidate;
            break;
        end
    end

    if isempty(bestRoot)
        error('Could not find the dat root folder. Checked preferred root:\n%s', datRoot);
    end

    warning('Preferred dat root was not found. Using detected folder:\n%s', bestRoot);
    datRoot = bestRoot;
end

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

function checkAllSeedLists(seedTables, methodLabels)
    refSeed = [];
    refLabel = '';
    allComparable = true;
    allMatch = true;

    for i = 1:numel(seedTables)
        S = seedTables{i};
        if isempty(S)
            allComparable = false;
            continue;
        end
        if size(S, 2) < 2
            warning('%s seed_list.dat has fewer than 2 columns; seed order cannot be checked.', ...
                char(methodLabels(i)));
            allComparable = false;
            continue;
        end

        seedCol = S(:, 2);
        if isempty(refSeed)
            refSeed = seedCol;
            refLabel = char(methodLabels(i));
        else
            if numel(seedCol) ~= numel(refSeed) || ~isequal(seedCol, refSeed)
                allMatch = false;
                warning('Seed list mismatch: %s does not match %s.', ...
                    char(methodLabels(i)), refLabel);
            end
        end
    end

    if allComparable && allMatch
        fprintf('All seed lists match.\n\n');
    else
        warning(['One or more seed lists could not be verified or did not match. ', ...
            'The analysis still uses an inner join by case/run, but interpretation requires caution.']);
    end
end

function T = loadDatFile(path)
    % Expected columns:
    % 1 run, 2 case, 3 t, 4 x error, 5 y error, 6 z error,
    % 7 e_v_dir, 8 e_v_mag, 9 phi, 10 theta, 11 psi, 12 p, 13 q, 14 r,
    % 15:18 Agent_Th1~4, 19:22 Total_Th1~4, 23:31 position/velocity logs.
    % A legacy 25-column dat file is also accepted; missing velocity log
    % columns are filled with NaN.

    colNames31 = {'run','case','t','x','y','z','e_v_dir','e_v_mag', ...
        'phi','theta','psi','p','q','r', ...
        'Ag1','Ag2','Ag3','Ag4', ...
        'Tt1','Tt2','Tt3','Tt4', ...
        'x_pos','y_pos','z_pos', ...
        'x_vel','y_vel','z_vel', ...
        'x_vel_cmd','y_vel_cmd','z_vel_cmd'};

    M = readmatrix(path);
    M = M(~all(isnan(M), 2), :);

    if isempty(M)
        error('No numeric data could be read from:\n%s', path);
    end

    nCol = size(M, 2);
    if nCol == 25
        M = [M, nan(size(M, 1), 6)];
        warning('Legacy 25-column dat file detected. Velocity log columns were filled with NaN:\n%s', path);
    elseif nCol ~= 31
        error('Unexpected dat column count. Read %d columns; expected 25 or 31.\nFile: %s', ...
            nCol, path);
    end

    T = array2table(M, 'VariableNames', colNames31);
    T.run = round(T.run);
    T.case = round(T.case);

    validIdx = ~isnan(T.run) & ~isnan(T.case) & ~isnan(T.t);
    T = T(validIdx, :);
end

function R = computePerRunRmse(T)
    [G, caseVals, runVals] = findgroups(T.case, T.run);

    posRmse = splitapply(@localPosRmse, T.x, T.y, T.z, G);
    velRmse = splitapply(@localScalarRmse, T.e_v_mag, G);

    R = table(caseVals(:), runVals(:), posRmse(:), velRmse(:), ...
        'VariableNames', {'case','run','pos_rmse','vel_rmse'});
end

function y = localPosRmse(x, yv, z)
    y = sqrt(meanOmitNaN(x.^2 + yv.^2 + z.^2));
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

function s = stdOmitNaN(x)
    x = x(~isnan(x));
    if numel(x) <= 1
        s = NaN;
    else
        s = std(x, 0);
    end
end

function longTable = buildLongTable(rmseTables, methodLabels)
    longTable = table();
    for i = 1:numel(rmseTables)
        R = rmseTables{i};
        method = repmat(cellstr(char(methodLabels(i))), height(R), 1);
        tmp = table(R.case, R.run, method, R.pos_rmse, ...
            'VariableNames', {'case','run','method','pos_rmse'});
        longTable = [longTable; tmp]; %#ok<AGROW>
    end
end

function wideTable = buildWideTable(rmseTables, safeMethodNames)
    wideTable = rmseTables{1}(:, {'case','run','pos_rmse'});
    wideTable.Properties.VariableNames = {'case','run',safeMethodNames{1}};

    for i = 2:numel(rmseTables)
        tmp = rmseTables{i}(:, {'case','run','pos_rmse'});
        tmp.Properties.VariableNames = {'case','run',safeMethodNames{i}};
        wideTable = innerjoin(wideTable, tmp, 'Keys', {'case','run'});
    end

    wideTable = sortrows(wideTable, {'case','run'});
end

function out = headRows(T, n)
    out = T(1:min(n, height(T)), :);
end

function resultTable = runCasewiseFriedman(wideTable, safeMethodNames, caseNames)
    cases = unique(wideTable.case);
    cases = sort(cases(:));
    nCase = numel(cases);
    nMethod = numel(safeMethodNames);

    Case = cell(nCase, 1);
    nPair = nan(nCase, 1);
    means = nan(nCase, nMethod);
    stds = nan(nCase, nMethod);
    Friedman_p = nan(nCase, 1);

    for i = 1:nCase
        c = cases(i);
        idx = wideTable.case == c;
        X = tableToMatrix(wideTable(idx, safeMethodNames));
        X = X(all(~isnan(X), 2), :);

        nPair(i) = size(X, 1);
        if nPair(i) ~= 30
            warning('Case %d has nPair = %d, not 30.', c, nPair(i));
        end

        for m = 1:nMethod
            means(i, m) = meanOmitNaN(X(:, m));
            stds(i, m) = stdOmitNaN(X(:, m));
        end

        if size(X, 1) >= 2
            try
                Friedman_p(i) = friedman(X, 1, 'off');
            catch ME
                warning('Friedman test failed for Case %d: %s', c, ME.message);
            end
        end

        Case{i} = caseLabel(c, caseNames);
    end

    resultTable = table(Case, nPair, Friedman_p, ...
        'VariableNames', {'Case','nPair','Friedman_p'});

    for m = 1:nMethod
        resultTable.(['mean_' safeMethodNames{m}]) = means(:, m);
        resultTable.(['std_' safeMethodNames{m}]) = stds(:, m);
    end
end

function posthocTable = runSacPosthoc(wideTable, safeMethodNames, caseNames, nBoot)
    sacName = 'SAC';
    if ~any(strcmp(safeMethodNames, sacName))
        error('SAC column was not found in safeMethodNames.');
    end

    refNames = safeMethodNames(1:3);
    cases = unique(wideTable.case);
    cases = sort(cases(:));

    nOut = numel(cases) * numel(refNames);
    Case = cell(nOut, 1);
    Comparison = cell(nOut, 1);
    Reference_mean_RMSE = nan(nOut, 1);
    SAC_mean_RMSE = nan(nOut, 1);
    Improvement_percent = nan(nOut, 1);
    Boot_CI95_low = nan(nOut, 1);
    Boot_CI95_high = nan(nOut, 1);
    Wilcoxon_p = nan(nOut, 1);
    Holm_p_within_case = nan(nOut, 1);
    Rank_biserial_effect = nan(nOut, 1);
    wins = cell(nOut, 1);
    Sign_test_p = nan(nOut, 1);
    nPair = nan(nOut, 1);
    outRow = 0;

    for i = 1:numel(cases)
        c = cases(i);
        idx = wideTable.case == c;

        caseP = nan(numel(refNames), 1);
        startRow = outRow + 1;

        for r = 1:numel(refNames)
            outRow = outRow + 1;
            refName = refNames{r};
            X = tableToMatrix(wideTable(idx, {refName, sacName}));
            X = X(all(~isnan(X), 2), :);
            ref = X(:, 1);
            sac = X(:, 2);
            d = ref - sac;

            meanRef = meanOmitNaN(ref);
            meanSac = meanOmitNaN(sac);
            impr = (meanRef - meanSac) / meanRef * 100;
            [ciLo, ciHi] = bootstrapImprovementCi(ref, sac, nBoot);

            if numel(d) > 0 && any(d ~= 0)
                try
                    pWilcox = signrank(ref, sac, 'tail', 'right');
                catch ME
                    pWilcox = NaN;
                    warning('signrank failed for Case %d, %s vs SAC: %s', c, refName, ME.message);
                end
            else
                pWilcox = NaN;
            end

            n = numel(d);
            nWins = sum(d > 0);
            if n > 0
                pSign = 1 - binocdf(nWins - 1, n, 0.5);
            else
                pSign = NaN;
            end

            Case{outRow, 1} = caseLabel(c, caseNames);
            Comparison{outRow, 1} = ['SAC vs ' refName];
            Reference_mean_RMSE(outRow, 1) = meanRef;
            SAC_mean_RMSE(outRow, 1) = meanSac;
            Improvement_percent(outRow, 1) = impr;
            Boot_CI95_low(outRow, 1) = ciLo;
            Boot_CI95_high(outRow, 1) = ciHi;
            Wilcoxon_p(outRow, 1) = pWilcox;
            Rank_biserial_effect(outRow, 1) = rankBiserialFromDiff(d);
            wins{outRow, 1} = sprintf('%d/%d', nWins, n);
            Sign_test_p(outRow, 1) = pSign;
            nPair(outRow, 1) = n;

            caseP(r) = pWilcox;
        end

        caseRows = startRow:(startRow + numel(refNames) - 1);
        Holm_p_within_case(caseRows) = holmCorrection(caseP);
    end

    Holm_p_global = holmCorrection(Wilcoxon_p);

    posthocTable = table(Case, Comparison, Reference_mean_RMSE, SAC_mean_RMSE, ...
        Improvement_percent, Boot_CI95_low, Boot_CI95_high, Wilcoxon_p, ...
        Holm_p_within_case, Holm_p_global, Rank_biserial_effect, wins, ...
        Sign_test_p, nPair, ...
        'VariableNames', {'Case','Comparison','Reference_mean_RMSE','SAC_mean_RMSE', ...
        'Improvement_percent','Boot_CI95_low','Boot_CI95_high','Wilcoxon_p', ...
        'Holm_p_within_case','Holm_p_global','Rank_biserial_effect', ...
        'wins','Sign_test_p','nPair'});
end

function manuscriptMeanTable = makeManuscriptMeanTable(friedmanTable)
    Case = string(friedmanTable.Case);
    NoAgent_mean = formatNumberColumn(friedmanTable.mean_NoAgent, '%.4f');
    DDPG_mean = formatNumberColumn(friedmanTable.mean_DDPG, '%.4f');
    TD3_mean = formatNumberColumn(friedmanTable.mean_TD3, '%.4f');
    SAC_mean = formatNumberColumn(friedmanTable.mean_SAC, '%.4f');
    Friedman_p = strings(height(friedmanTable), 1);

    for i = 1:height(friedmanTable)
        Friedman_p(i) = formatP(friedmanTable.Friedman_p(i));
    end

    manuscriptMeanTable = table(Case, NoAgent_mean, DDPG_mean, TD3_mean, ...
        SAC_mean, Friedman_p);
end

function T = makeManuscriptPairwiseTable(posthocTable, comparisonName)
    idx = strcmp(posthocTable.Comparison, comparisonName);
    P = posthocTable(idx, :);

    Case = string(P.Case);
    Reference = formatNumberColumn(P.Reference_mean_RMSE, '%.4f');
    SAC = formatNumberColumn(P.SAC_mean_RMSE, '%.4f');
    Improvement_percent = formatNumberColumn(P.Improvement_percent, '%.2f');
    CI95 = strings(height(P), 1);
    Holm_p = strings(height(P), 1);
    Effect_size = formatNumberColumn(P.Rank_biserial_effect, '%.3f');
    Wins = string(P.wins);

    for i = 1:height(P)
        CI95(i) = formatCI(P.Boot_CI95_low(i), P.Boot_CI95_high(i));
        Holm_p(i) = formatP(P.Holm_p_within_case(i));
    end

    T = table(Case, Reference, SAC, Improvement_percent, CI95, Holm_p, ...
        Effect_size, Wins);
end

function T = makeManuscriptPosthocCompactTable(posthocTable)
    Case = string(posthocTable.Case);
    Comparison = string(posthocTable.Comparison);
    Improvement_percent = formatNumberColumn(posthocTable.Improvement_percent, '%.2f');
    CI95 = strings(height(posthocTable), 1);
    Holm_p = strings(height(posthocTable), 1);
    Effect_size = formatNumberColumn(posthocTable.Rank_biserial_effect, '%.3f');
    Wins = string(posthocTable.wins);

    for i = 1:height(posthocTable)
        CI95(i) = formatCI(posthocTable.Boot_CI95_low(i), posthocTable.Boot_CI95_high(i));
        Holm_p(i) = formatP(posthocTable.Holm_p_within_case(i));
    end

    T = table(Case, Comparison, Improvement_percent, CI95, Holm_p, ...
        Effect_size, Wins);
end

function s = formatP(p)
    if isnan(p)
        s = "NaN";
    elseif p < 0.001
        s = string(sprintf('%.2e', p));
    else
        s = string(sprintf('%.4f', p));
    end
end

function s = formatCI(lo, hi)
    if isnan(lo) || isnan(hi)
        s = "[NaN, NaN]";
    else
        s = string(sprintf('[%.2f, %.2f]', lo, hi));
    end
end

function col = formatNumberColumn(values, fmt)
    col = strings(numel(values), 1);
    for i = 1:numel(values)
        if isnan(values(i))
            col(i) = "NaN";
        else
            col(i) = string(sprintf(fmt, values(i)));
        end
    end
end

function [lo, hi] = bootstrapImprovementCi(ref, sac, nBoot)
    valid = ~isnan(ref) & ~isnan(sac);
    ref = ref(valid);
    sac = sac(valid);
    n = numel(ref);

    if n == 0
        lo = NaN;
        hi = NaN;
        return;
    end

    bootVal = nan(nBoot, 1);
    for k = 1:nBoot
        idx = randi(n, n, 1);
        refMean = mean(ref(idx));
        sacMean = mean(sac(idx));
        bootVal(k) = (refMean - sacMean) / refMean * 100;
    end

    ci = prctile(bootVal, [2.5, 97.5]);
    lo = ci(1);
    hi = ci(2);
end

function rb = rankBiserialFromDiff(d)
    d = d(~isnan(d));
    d = d(d ~= 0);

    if isempty(d)
        rb = NaN;
        return;
    end

    r = tiedrank(abs(d));
    Rpos = sum(r(d > 0));
    Rneg = sum(r(d < 0));
    rb = (Rpos - Rneg) / (Rpos + Rneg);
end

function adjP = holmCorrection(pvals)
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
    runningMax = 0;

    for k = 1:m
        adjusted = (m - k + 1) * sortedP(k);
        runningMax = max(runningMax, adjusted);
        adjSorted(k) = min(runningMax, 1);
    end

    tmp = nan(m, 1);
    tmp(order) = adjSorted;
    adjP(validIdx) = tmp;
end

function makeBoxplotByCase(longTable, methodLabels, caseNames, outDir)
    outPng = fullfile(outDir, 'boxplot_pos_rmse_methods.png');
    cases = unique(longTable.case);
    cases = sort(cases(:));

    fig = figure('Color', 'w', 'Position', [100 100 1200 800]);
    useTiled = true;
    try
        tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    catch
        useTiled = false;
    end

    for i = 1:numel(cases)
        if useTiled
            nexttile;
        else
            subplot(2, 2, i);
        end

        c = cases(i);
        idx = longTable.case == c;
        data = [];
        group = [];
        for m = 1:numel(methodLabels)
            methodIdx = idx & strcmp(longTable.method, char(methodLabels(m)));
            data = [data; longTable.pos_rmse(methodIdx)]; %#ok<AGROW>
            group = [group; m * ones(sum(methodIdx), 1)]; %#ok<AGROW>
        end

        boxplot(data, group, 'Labels', cellstr(methodLabels));
        grid on; box on;
        ylabel('3D position RMSE (m)');
        title(caseLabel(c, caseNames));
        set(gca, 'FontSize', 10);
    end

    saveFigure300(fig, outPng);
end

function makeImprovementBarPlot(posthocTable, ~, outDir)
    outPng = fullfile(outDir, 'sac_posthoc_improvement.png');
    cases = unique(posthocTable.Case, 'stable');
    refs = {'NoAgent', 'DDPG', 'TD3'};
    Y = nan(numel(cases), numel(refs));

    for c = 1:numel(cases)
        for r = 1:numel(refs)
            comp = ['SAC vs ' refs{r}];
            idx = strcmp(posthocTable.Case, cases{c}) & strcmp(posthocTable.Comparison, comp);
            if any(idx)
                Y(c, r) = posthocTable.Improvement_percent(find(idx, 1));
            end
        end
    end

    fig = figure('Color', 'w', 'Position', [100 100 950 520]);
    bar(Y, 'grouped');
    grid on; box on;
    ylabel('Improvement of SAC (%)');
    xlabel('Case');
    title('SAC-centered 3D position RMSE improvement');
    set(gca, 'XTick', 1:numel(cases), 'XTickLabel', cases, 'FontSize', 11);
    legend({'vs No Agent','vs DDPG','vs TD3'}, 'Location', 'best');
    ylineCompat(0);

    saveFigure300(fig, outPng);
end

function correlationAnalysisSacNoAgent(wideTable, caseNames, outDir)
    outPng = fullfile(outDir, 'sac_vs_noagent_reduction_vs_baseline.png');
    baseline = wideTable.NoAgent;
    sac = wideTable.SAC;
    reduction = baseline - sac;

    valid = ~isnan(baseline) & ~isnan(reduction);
    if sum(valid) >= 2
        [rho, pval] = corr(baseline(valid), reduction(valid), ...
            'Type', 'Spearman', 'Rows', 'complete');
    else
        rho = NaN;
        pval = NaN;
    end

    fig = figure('Color', 'w', 'Position', [100 100 760 560]);
    hold on; grid on; box on;

    colors = [ ...
        0.0000 0.4470 0.7410; ...
        0.4660 0.6740 0.1880; ...
        0.8500 0.3250 0.0980; ...
        0.4940 0.1840 0.5560];

    cases = unique(wideTable.case);
    cases = sort(cases(:));
    for i = 1:numel(cases)
        c = cases(i);
        idx = wideTable.case == c;
        colorIdx = mod(i - 1, size(colors, 1)) + 1;
        scatter(baseline(idx), reduction(idx), 42, 'filled', ...
            'MarkerFaceColor', colors(colorIdx, :), ...
            'MarkerEdgeColor', [1 1 1], ...
            'DisplayName', caseLabel(c, caseNames));
    end

    if sum(valid) >= 2
        coeff = polyfit(baseline(valid), reduction(valid), 1);
        xs = linspace(min(baseline(valid)), max(baseline(valid)), 100);
        plot(xs, polyval(coeff, xs), 'k--', 'LineWidth', 1.2, ...
            'DisplayName', 'Linear trend');
    end

    ylineCompat(0);
    xlabel('No Agent 3D position RMSE (m)');
    ylabel('Absolute RMSE reduction by SAC (m)');
    title(sprintf('SAC vs No Agent reduction (Spearman rho = %.3f, p = %.2e)', rho, pval));
    legend('Location', 'best');
    set(gca, 'FontSize', 11);

    saveFigure300(fig, outPng);
end

function ylineCompat(y)
    xl = xlim;
    plot(xl, [y y], '-', 'Color', [0.45 0.45 0.45], 'LineWidth', 0.8);
end

function saveFigure300(fig, outPng)
    try
        exportgraphics(fig, outPng, 'Resolution', 300);
    catch
        print(fig, outPng, '-dpng', '-r300');
    end
    close(fig);
end

function printConsoleSummary(friedmanTable, posthocTable, wideTable, safeMethodNames, methodLabels)
    fprintf('\n======================================================================\n');
    fprintf('Console summary for manuscript drafting\n');
    fprintf('======================================================================\n');

    for i = 1:height(friedmanTable)
        fprintf('%s: Friedman p = %.4g, nPair = %d\n', ...
            friedmanTable.Case{i}, friedmanTable.Friedman_p(i), friedmanTable.nPair(i));
    end

    fprintf('\nMean RMSE ordering by case:\n');
    cases = unique(wideTable.case);
    cases = sort(cases(:));
    for i = 1:numel(cases)
        c = cases(i);
        idx = wideTable.case == c;
        meanVals = nan(1, numel(safeMethodNames));
        for m = 1:numel(safeMethodNames)
            meanVals(m) = meanOmitNaN(wideTable{idx, safeMethodNames{m}});
        end
        [bestVal, bestIdx] = min(meanVals);
        fprintf('%s: best mean RMSE = %s (%.6g m)\n', ...
            caseLabel(c, {'Hovering', 'Line', 'Circular', 'Figure-8'}), ...
            char(methodLabels(bestIdx)), bestVal);
    end

    fprintf('\nSAC mean RMSE comparison by case:\n');
    for i = 1:height(posthocTable)
        if posthocTable.Improvement_percent(i) > 0
            direction = 'lower';
        elseif posthocTable.Improvement_percent(i) < 0
            direction = 'higher';
        else
            direction = 'equal';
        end
        fprintf('%s, %s: SAC mean RMSE is %s; improvement = %.2f%%; Holm-within-case p = %.4g\n', ...
            posthocTable.Case{i}, posthocTable.Comparison{i}, direction, ...
            posthocTable.Improvement_percent(i), posthocTable.Holm_p_within_case(i));
    end

    sigIdx = posthocTable.Holm_p_within_case < 0.05;
    fprintf('\nSignificant SAC-centered comparisons by within-case Holm p < 0.05:\n');
    if any(sigIdx)
        disp(posthocTable(sigIdx, {'Case','Comparison','Improvement_percent','Holm_p_within_case','Holm_p_global'}));
    else
        fprintf('None.\n');
    end

    sacBestAll = true;
    for i = 1:numel(cases)
        c = cases(i);
        idx = wideTable.case == c;
        meanVals = nan(1, numel(safeMethodNames));
        for m = 1:numel(safeMethodNames)
            meanVals(m) = meanOmitNaN(wideTable{idx, safeMethodNames{m}});
        end
        [~, bestIdx] = min(meanVals);
        sacBestAll = sacBestAll && strcmp(safeMethodNames{bestIdx}, 'SAC');
    end

    if sacBestAll
        fprintf('\nSAC has the lowest mean RMSE in every case.\n');
    else
        fprintf('\nSAC does not have the lowest mean RMSE in every case.\n');
    end
end

function X = tableToMatrix(T)
    X = zeros(height(T), width(T));
    for i = 1:width(T)
        X(:, i) = T{:, i};
    end
end

function label = caseLabel(c, caseNames)
    if c >= 1 && c <= numel(caseNames)
        label = sprintf('Case %d (%s)', c, caseNames{c});
    else
        label = sprintf('Case %d', c);
    end
end
