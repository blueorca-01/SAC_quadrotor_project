clc; clear; close all;

%% =========================================================
% 0) User settings
% =========================================================
mdl = "vector";
open_system(mdl);

rootDir = "result";
datRoot = fullfile(rootDir, "실험 결과 dat 파일 모음");
outDir = fullfile(rootDir, "thrust_statistics_result");

methodLabels = ["DDPG", "TD3", "SAC"];
fnameList = [
    "(Huber)(0.02)DDPG_ver1(mod_1)"
    "(Huber)TD3_ver1(mod_1)"
    "(cpu2)(Huber)(0.02)SAC_ver4(mod_1)"
];

% Optional selected case/run time-history plots.
makeTimeHistoryPlots = false;
selectedCase = 1;   % 1~4
selectedRun  = 1;   % 1~30

% Auxiliary thrust limit ratio.
percent = 0.02;

% Saturation decision tolerance.
% 0.999 means values at or above 99.9% of the limit are treated as saturated.
satTol = 0.999;

if ~exist(outDir, "dir")
    mkdir(outDir);
end

datRoot = resolveDatRoot(rootDir, datRoot, fnameList);

%% =========================================================
% 1) Read m, g from model
% =========================================================
blk_m = mdl + "/Hybrid RL-PD Control System/Mass";
blk_g = mdl + "/Hybrid RL-PD Control System/Gravity";

m = str2double(get_param(blk_m, "Value"));
g = str2double(get_param(blk_g, "Value"));

Thrust_limit_total = 1.5 * m * g;          % baseline total thrust limit
Base_motor_max     = Thrust_limit_total/4; % baseline per-motor max

Agent_motor_lim    = percent * Thrust_limit_total;      % per-motor auxiliary limit
Total_motor_max    = Base_motor_max + Agent_motor_lim;  % per-motor total max

fprintf("\n===== Thrust limit setting =====\n");
fprintf("m = %.6f kg\n", m);
fprintf("g = %.6f m/s^2\n", g);
fprintf("Baseline total thrust limit = %.6f N\n", Thrust_limit_total);
fprintf("Baseline per-motor max      = %.6f N\n", Base_motor_max);
fprintf("Agent per-motor limit       = +/- %.6f N\n", Agent_motor_lim);
fprintf("Total per-motor max         = %.6f N\n", Total_motor_max);
fprintf("Output dir                  = %s\n", outDir);

%% =========================================================
% 2) Column indices
% =========================================================
% Based on data.m output order.
col.run      = 1;
col.caseNum  = 2;
col.t        = 3;

col.Agent_Th = 15:18;
col.Total_Th = 19:22;

%% =========================================================
% 3) Multi-method thrust statistics
% =========================================================
allDetailTables = cell(numel(methodLabels), 1);
allAvgTables = cell(numel(methodLabels), 1);

for mi = 1:numel(methodLabels)
    method = methodLabels(mi);
    fname = fnameList(mi);
    datFile = fullfile(datRoot, fname, fname + "_all_runs.dat");

    fprintf("\n[%s]\n", method);
    fprintf("Reading dat file:\n%s\n", datFile);

    D = readDatMatrix(datFile);
    fprintf("Loaded data size: %d rows x %d columns\n", size(D,1), size(D,2));

    if makeTimeHistoryPlots
        makeSelectedTimeHistoryPlots(D, col, method, selectedCase, selectedRun, ...
            Base_motor_max, Agent_motor_lim, Total_motor_max);
    end

    [detailTable, avgTable] = computeMethodThrustTables(D, col, method, ...
        Agent_motor_lim, Total_motor_max, satTol);

    allDetailTables{mi} = detailTable;
    allAvgTables{mi} = avgTable;
end

motorDetailTable = vertcat(allDetailTables{:});
avgByCaseMethodTable = vertcat(allAvgTables{:});

summaryLongTable = makeCompactManuscriptTable(avgByCaseMethodTable, methodLabels);
summaryWideTable = makeWideSummaryTable(avgByCaseMethodTable, methodLabels);

disp(" ");
disp("===== Thrust manuscript summary table =====");
disp(summaryLongTable);

disp(" ");
disp("===== Thrust wide summary table =====");
disp(summaryWideTable);

disp(" ");
disp("===== Thrust motor detail table =====");
disp(motorDetailTable);

writetable(summaryLongTable, fullfile(outDir, "thrust_summary_long.csv"));
writetable(summaryWideTable, fullfile(outDir, "thrust_summary_wide.csv"));
writetable(motorDetailTable, fullfile(outDir, "thrust_motor_detail.csv"));

fprintf("\nCSV outputs saved:\n%s\n", outDir);

%% =========================================================
% 4) Manuscript grouped bar plots
% =========================================================
makeGroupedMethodBarPlot(avgByCaseMethodTable, methodLabels, ...
    "AuxSatAvg_percent", ...
    "Auxiliary saturation average (%)", ...
    "Auxiliary thrust saturation by algorithm", ...
    fullfile(outDir, "aux_saturation_avg_by_algorithm.png"), ...
    false);

makeGroupedMethodBarPlot(avgByCaseMethodTable, methodLabels, ...
    "TotalSatTimeAvg_percent", ...
    "Total saturation time average (%)", ...
    "Total thrust saturation time by algorithm", ...
    fullfile(outDir, "total_saturation_time_avg_by_algorithm.png"), ...
    false);

makeGroupedMethodBarPlot(avgByCaseMethodTable, methodLabels, ...
    "PeakTotalAvg_percent", ...
    "Peak total thrust average (% of motor limit)", ...
    "Peak total thrust by algorithm", ...
    fullfile(outDir, "peak_total_thrust_avg_by_algorithm.png"), ...
    true);

fprintf("\nPNG outputs saved:\n%s\n", outDir);

%% =========================================================
% Local functions
% =========================================================
function datRoot = resolveDatRoot(rootDir, preferredRoot, fnameList)
    datRoot = char(preferredRoot);
    if isfolder(datRoot)
        return;
    end

    rootDir = char(rootDir);
    d = dir(rootDir);
    for i = 1:numel(d)
        if ~d(i).isdir || strcmp(d(i).name, ".") || strcmp(d(i).name, "..")
            continue;
        end

        candidate = fullfile(rootDir, d(i).name);
        firstMethodDir = fullfile(candidate, char(fnameList(1)));
        if isfolder(firstMethodDir)
            datRoot = candidate;
            return;
        end
    end

    error("Data root was not found. Preferred path:\n%s", preferredRoot);
end

function D = readDatMatrix(datFile)
    if ~exist(datFile, "file")
        error("dat file was not found:\n%s", datFile);
    end

    D = readmatrix(datFile, ...
        "FileType", "text", ...
        "Delimiter", "\t", ...
        "CommentStyle", "%");

    if size(D,2) < 30
        warning("First readmatrix result has %d columns. Retrying without tab delimiter.", size(D,2));
        D = readmatrix(datFile, ...
            "FileType", "text", ...
            "CommentStyle", "%");
    end

    if size(D,2) < 30
        error("dat file has fewer columns than expected. Current column count: %d.", size(D,2));
    end
end

function [detailTable, avgTable] = computeMethodThrustTables(D, col, method, ...
    Agent_motor_lim, Total_motor_max, satTol)

    caseList = unique(D(:, col.caseNum));
    caseList = sort(caseList(:));
    nCase = numel(caseList);
    nMotor = 4;
    nRows = nCase * nMotor;

    Method = strings(nRows, 1);
    Case = zeros(nRows, 1);
    Motor = zeros(nRows, 1);
    AuxSat_percent = zeros(nRows, 1);
    MaxAbsAgent_N = zeros(nRows, 1);
    PeakTotal_N = zeros(nRows, 1);
    PeakTotal_percent = zeros(nRows, 1);
    TotalSatTime_percent = zeros(nRows, 1);

    row = 0;
    for ci = 1:nCase
        c = caseList(ci);
        idxCase = D(:, col.caseNum) == c;
        Agent_Th = D(idxCase, col.Agent_Th);
        Total_Th = D(idxCase, col.Total_Th);

        for motorIdx = 1:nMotor
            row = row + 1;
            absAgent = abs(Agent_Th(:, motorIdx));
            totalMotor = Total_Th(:, motorIdx);

            Method(row) = method;
            Case(row) = c;
            Motor(row) = motorIdx;
            AuxSat_percent(row) = 100 * mean(absAgent >= satTol * Agent_motor_lim);
            MaxAbsAgent_N(row) = max(absAgent);
            PeakTotal_N(row) = max(totalMotor);
            PeakTotal_percent(row) = 100 * PeakTotal_N(row) / Total_motor_max;
            TotalSatTime_percent(row) = 100 * mean(totalMotor >= satTol * Total_motor_max);
        end
    end

    detailTable = table(Method, Case, Motor, AuxSat_percent, MaxAbsAgent_N, ...
        PeakTotal_N, PeakTotal_percent, TotalSatTime_percent);

    MethodAvg = strings(nCase, 1);
    CaseAvg = zeros(nCase, 1);
    AuxSatAvg_percent = zeros(nCase, 1);
    PeakTotalAvg_percent = zeros(nCase, 1);
    TotalSatTimeAvg_percent = zeros(nCase, 1);

    for ci = 1:nCase
        idx = Case == caseList(ci);
        MethodAvg(ci) = method;
        CaseAvg(ci) = caseList(ci);
        AuxSatAvg_percent(ci) = mean(AuxSat_percent(idx));
        PeakTotalAvg_percent(ci) = mean(PeakTotal_percent(idx));
        TotalSatTimeAvg_percent(ci) = mean(TotalSatTime_percent(idx));
    end

    avgTable = table(MethodAvg, CaseAvg, AuxSatAvg_percent, ...
        PeakTotalAvg_percent, TotalSatTimeAvg_percent, ...
        'VariableNames', {'Method', 'Case', 'AuxSatAvg_percent', ...
        'PeakTotalAvg_percent', 'TotalSatTimeAvg_percent'});
end

function T = makeCompactManuscriptTable(avgTable, methodLabels)
    caseList = unique(avgTable.Case);
    caseList = sort(caseList(:));
    metricNames = ["AuxSatAvg_percent", "PeakTotalAvg_percent", "TotalSatTimeAvg_percent"];
    metricLabels = ["AuxSatAvg_percent", "PeakTotalAvg_percent", "TotalSatTimeAvg_percent"];

    nRows = numel(caseList) * numel(metricNames);
    Case = strings(nRows, 1);
    Metric = strings(nRows, 1);
    values = nan(nRows, numel(methodLabels));

    row = 0;
    methodStr = string(avgTable.Method);
    for ci = 1:numel(caseList)
        for k = 1:numel(metricNames)
            row = row + 1;
            Case(row) = "Case " + string(caseList(ci));
            Metric(row) = metricLabels(k);

            for mi = 1:numel(methodLabels)
                idx = avgTable.Case == caseList(ci) & methodStr == methodLabels(mi);
                if any(idx)
                    values(row, mi) = avgTable{find(idx, 1), char(metricNames(k))};
                end
            end
        end
    end

    T = table(Case, Metric);
    for mi = 1:numel(methodLabels)
        T.(char(methodLabels(mi))) = values(:, mi);
    end
end

function T = makeWideSummaryTable(avgTable, methodLabels)
    caseList = unique(avgTable.Case);
    caseList = sort(caseList(:));
    T = table(caseList, 'VariableNames', {'Case'});

    metricNames = ["AuxSatAvg_percent", "PeakTotalAvg_percent", "TotalSatTimeAvg_percent"];
    methodStr = string(avgTable.Method);
    for mi = 1:numel(methodLabels)
        for k = 1:numel(metricNames)
            colName = char(methodLabels(mi) + "_" + metricNames(k));
            vals = nan(numel(caseList), 1);
            for ci = 1:numel(caseList)
                idx = avgTable.Case == caseList(ci) & methodStr == methodLabels(mi);
                if any(idx)
                    vals(ci) = avgTable{find(idx, 1), char(metricNames(k))};
                end
            end
            T.(colName) = vals;
        end
    end
end

function makeGroupedMethodBarPlot(avgTable, methodLabels, metricName, yLabelText, ...
    plotTitle, outPng, addHundredLine)

    caseList = unique(avgTable.Case);
    caseList = sort(caseList(:));
    Y = nan(numel(caseList), numel(methodLabels));
    methodStr = string(avgTable.Method);

    for ci = 1:numel(caseList)
        for mi = 1:numel(methodLabels)
            idx = avgTable.Case == caseList(ci) & methodStr == methodLabels(mi);
            if any(idx)
                Y(ci, mi) = avgTable{find(idx, 1), char(metricName)};
            end
        end
    end

    fig = figure("Name", plotTitle, "Color", "w", "Position", [100 100 900 520]);
    bar(Y, "grouped");
    grid on; box on;
    xticks(1:numel(caseList));
    xticklabels("Case " + string(caseList));
    xlabel("Case");
    ylabel(yLabelText);
    title(plotTitle);
    legend(methodLabels, "Location", "best");

    if addHundredLine
        yline(100, "r--", "100%", "LineWidth", 1.5, ...
            "LabelHorizontalAlignment", "left", ...
            "LabelVerticalAlignment", "bottom");
    end

    finiteY = Y(~isnan(Y));
    if isempty(finiteY)
        ylim([0, 1]);
    elseif addHundredLine
        ylim([0, max(110, max(finiteY) * 1.15)]);
    else
        ylim([0, max(1, max(finiteY) * 1.2)]);
    end

    saveFigure300(fig, outPng);
end

function makeSelectedTimeHistoryPlots(D, col, method, selectedCase, selectedRun, ...
    Base_motor_max, Agent_motor_lim, Total_motor_max)

    idx = (D(:, col.caseNum) == selectedCase) & (D(:, col.run) == selectedRun);
    if ~any(idx)
        warning("Selected case/run data was not found for %s. case=%d, run=%d", ...
            method, selectedCase, selectedRun);
        return;
    end

    S = D(idx, :);
    t = S(:, col.t);
    Agent_Th = S(:, col.Agent_Th);
    Total_Th = S(:, col.Total_Th);
    Base_Th  = Total_Th - Agent_Th;

    fprintf("Selected data for %s: Case %d, Run %d, %d samples\n", ...
        method, selectedCase, selectedRun, length(t));

    namePrefix = method + ", Case " + selectedCase + ", Run " + selectedRun;

    plotThrust_2x2( ...
        t, Base_Th, ...
        "Baseline thrust, " + namePrefix, ...
        "Baseline thrust (N)", ...
        ["Baseline max"], ...
        [Base_motor_max], ...
        ["--"] ...
    );

    plotThrust_2x2( ...
        t, Agent_Th, ...
        "Auxiliary RL thrust, " + namePrefix, ...
        "Auxiliary thrust (N)", ...
        ["Upper limit", "Lower limit"], ...
        [Agent_motor_lim, -Agent_motor_lim], ...
        ["--", "--"] ...
    );

    plotThrust_2x2( ...
        t, Total_Th, ...
        "Total motor thrust, " + namePrefix, ...
        "Total thrust (N)", ...
        ["Baseline max", "Baseline + auxiliary max"], ...
        [Base_motor_max, Total_motor_max], ...
        ["--", "--"] ...
    );
end

function plotThrust_2x2(t, Y, figTitle, yLabelText, lineLabels, ylineValues, lineStyles)
    figure("Name", figTitle, "Color", "w");
    tiledlayout(2, 2, "TileSpacing", "compact", "Padding", "compact");

    for i = 1:4
        nexttile;
        plot(t, Y(:, i), "LineWidth", 1.2);
        grid on;
        xlabel("Time (s)");
        ylabel(yLabelText);
        title("Motor " + i);

        for k = 1:numel(ylineValues)
            yline(ylineValues(k), lineStyles(k), lineLabels(k), ...
                "LabelHorizontalAlignment", "left", ...
                "LabelVerticalAlignment", "bottom", ...
                "LineWidth", 1.0);
        end
    end

    sgtitle(figTitle);
end

function saveFigure300(fig, outPng)
    try
        exportgraphics(fig, outPng, "Resolution", 300);
    catch
        print(fig, outPng, "-dpng", "-r300");
    end
    close(fig);
end
