clc; clear;

%% =========================================================
%% SAC policy inference time analyzer
%% Measures only getAction(agent, observation), not Simulink simulation time.
%% =========================================================

Nwarmup = 100;
Nrepeat = 10000;
Ts = 0.05;  % control sampling time [s]

rootDir = "result";
matRoot = fullfile(rootDir, "실험 결과 mat 파일 모음");
datRoot = fullfile(rootDir, "실험 결과 dat 파일 모음");
fname = "(cpu2)(Huber)(0.02)SAC_ver4(mod_1)";
matFile = fullfile(matRoot, fname + ".mat");
datFile = fullfile(datRoot, fname, fname + "_all_runs.dat");

agentCandidates = [
    matFile
    fullfile(datRoot, fname, fname + ".mat")
    fullfile(datRoot, fname, "agent.mat")
    fullfile(datRoot, fname, "trainedAgent.mat")
    fullfile("result", fname + ".mat")
];

resultDir = fullfile(rootDir, "inference_time_results");
if ~exist(resultDir, "dir")
    mkdir(resultDir);
end

timestamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
summaryCsvFile = fullfile(resultDir, fname + "_inference_summary_" + timestamp + ".csv");
rawCsvFile = fullfile(resultDir, fname + "_inference_raw_" + timestamp + ".csv");

stage = "initialization";

try
    %% =========================================================
    %% 1) Load trained agent / actor
    %% =========================================================
    stage = "finding agent MAT file";
    agentFile = "";
    for k = 1:numel(agentCandidates)
        if exist(agentCandidates(k), "file")
            agentFile = agentCandidates(k);
            break;
        end
    end

    if agentFile == ""
        msg = "No agent MAT file was found. Checked paths:" + newline + ...
            strjoin("  - " + agentCandidates, newline);
        error("%s", msg);
    end

    fprintf("\n===== SAC policy inference time analyzer =====\n");
    fprintf("Agent file:\n%s\n", agentFile);

    stage = "loading agent MAT file";
    S = load(agentFile);

    stage = "selecting trainedAgent/agent from MAT variables";
    [policyObj, policyVarName] = localFindPolicyObject(S);
    fprintf("Selected policy object: %s  (class: %s)\n", policyVarName, class(policyObj));

    %% =========================================================
    %% 2) Prepare observation
    %% =========================================================
    stage = "reading observation specification";
    obsInfo = localGetObservationInfo(policyObj);
    obsTemplate = localCreateZeroObservation(obsInfo);
    obsDims = localObservationDims(obsTemplate);
    fprintf("Observation template dimension(s): %s\n", obsDims);

    stage = "creating observation sample";
    [obsNumeric, obsSource] = localCreateObservationFromDatOrZero(datFile, obsTemplate);
    fprintf("Observation source: %s\n", obsSource);

    stage = "selecting valid getAction input format";
    [actionFcn, inputDescription] = localSelectGetActionFunction(policyObj, obsNumeric);
    fprintf("getAction input format: %s\n", inputDescription);

    %% =========================================================
    %% 3) Warm-up
    %% =========================================================
    stage = "warm-up getAction calls";
    fprintf("\nWarm-up: %d calls...\n", Nwarmup);
    for i = 1:Nwarmup
        actionFcn();
    end

    %% =========================================================
    %% 4) Repeated inference timing
    %% =========================================================
    stage = "timing repeated getAction calls";
    fprintf("Timing: %d calls...\n", Nrepeat);
    inferenceTimeMs = zeros(Nrepeat, 1);

    for i = 1:Nrepeat
        tStart = tic;
        actionFcn();
        inferenceTimeMs(i) = toc(tStart) * 1000;
    end

    %% =========================================================
    %% 5) Statistics
    %% =========================================================
    stage = "computing statistics";
    meanMs = mean(inferenceTimeMs);
    stdMs = std(inferenceTimeMs);
    medianMs = median(inferenceTimeMs);
    minMs = min(inferenceTimeMs);
    maxMs = max(inferenceTimeMs);
    p95Ms = localPercentile(inferenceTimeMs, 95);
    meanPctTs = (meanMs / (Ts * 1000)) * 100;
    p95PctTs = (p95Ms / (Ts * 1000)) * 100;

    %% =========================================================
    %% 6) Print and save results
    %% =========================================================
    stage = "printing results";
    fprintf("\n===== Inference time result =====\n");
    fprintf("Nwarmup                         : %d\n", Nwarmup);
    fprintf("Nrepeat                         : %d\n", Nrepeat);
    fprintf("Ts                              : %.6f s (%.3f ms)\n", Ts, Ts * 1000);
    fprintf("mean inference time             : %.6f ms\n", meanMs);
    fprintf("std inference time              : %.6f ms\n", stdMs);
    fprintf("median inference time           : %.6f ms\n", medianMs);
    fprintf("min inference time              : %.6f ms\n", minMs);
    fprintf("max inference time              : %.6f ms\n", maxMs);
    fprintf("95th percentile inference time  : %.6f ms\n", p95Ms);
    fprintf("mean inference time / Ts        : %.6f %%\n", meanPctTs);
    fprintf("95th percentile time / Ts       : %.6f %%\n", p95PctTs);

    stage = "saving CSV files";
    summaryTable = table( ...
        string(agentFile), string(policyVarName), string(class(policyObj)), ...
        string(datFile), string(obsSource), string(inputDescription), ...
        Nwarmup, Nrepeat, Ts, Ts * 1000, ...
        meanMs, stdMs, medianMs, minMs, maxMs, p95Ms, meanPctTs, p95PctTs, ...
        'VariableNames', { ...
            "agentFile", "policyVariableName", "policyClass", ...
            "datFile", "observationSource", "getActionInputFormat", ...
            "Nwarmup", "Nrepeat", "Ts_s", "Ts_ms", ...
            "mean_ms", "std_ms", "median_ms", "min_ms", "max_ms", ...
            "p95_ms", "mean_percent_of_Ts", "p95_percent_of_Ts"});

    rawTable = table((1:Nrepeat)', inferenceTimeMs, ...
        'VariableNames', {'iteration', 'inference_time_ms'});

    writetable(summaryTable, summaryCsvFile);
    writetable(rawTable, rawCsvFile);

    fprintf("\nSaved summary CSV:\n%s\n", summaryCsvFile);
    fprintf("Saved raw timing CSV:\n%s\n", rawCsvFile);

catch ME
    fprintf(2, "\n[ERROR] Failed during stage: %s\n", stage);
    fprintf(2, "Message: %s\n", ME.message);
    rethrow(ME);
end

%% =========================================================
%% Local helper functions
%% =========================================================

function [obj, varName] = localFindPolicyObject(S)
names = string(fieldnames(S));

priorityNames = ["trainedAgent", "agent", "saved_agent", "savedAgent", ...
    "trained_agent", "actor", "policy", "agentObj"];

for p = 1:numel(priorityNames)
    idx = find(names == priorityNames(p), 1);
    if ~isempty(idx) && localCanUseGetAction(S.(names(idx)))
        obj = S.(names(idx));
        varName = names(idx);
        return;
    end
end

for i = 1:numel(names)
    candidate = S.(names(i));
    if localCanUseGetAction(candidate)
        obj = candidate;
        varName = names(i);
        return;
    end
end

for i = 1:numel(names)
    candidate = S.(names(i));
    if isstruct(candidate)
        subNames = string(fieldnames(candidate));
        for j = 1:numel(subNames)
            subCandidate = candidate.(subNames(j));
            if localCanUseGetAction(subCandidate)
                obj = subCandidate;
                varName = names(i) + "." + subNames(j);
                return;
            end
        end
    end
end

error("No trainedAgent, agent, rl.agent.AbstractAgent, or getAction-capable object was found in the MAT file.");
end

function tf = localCanUseGetAction(obj)
try
    if isa(obj, "rl.agent.AbstractAgent")
        tf = true;
        return;
    end
catch
end

try
    m = string(methods(obj));
    tf = any(m == "getAction");
catch
    tf = false;
end
end

function obsInfo = localGetObservationInfo(policyObj)
try
    obsInfo = getObservationInfo(policyObj);
    return;
catch
end

try
    obsInfo = policyObj.ObservationInfo;
    return;
catch
end

try
    obsInfo = getObservationInfo(getActor(policyObj));
    return;
catch
end

warning("Could not read observation specification. Using default zero observation size [11 1].");
obsInfo = rlNumericSpec([11 1]);
end

function obs = localCreateZeroObservation(obsInfo)
if iscell(obsInfo)
    obs = cell(size(obsInfo));
    for i = 1:numel(obsInfo)
        obs{i} = localZeroForOneSpec(obsInfo{i});
    end
elseif numel(obsInfo) > 1
    obs = cell(size(obsInfo));
    for i = 1:numel(obsInfo)
        obs{i} = localZeroForOneSpec(obsInfo(i));
    end
else
    obs = localZeroForOneSpec(obsInfo);
end
end

function z = localZeroForOneSpec(spec)
dims = localSpecDimensions(spec);
z = zeros(dims);
end

function dims = localSpecDimensions(spec)
try
    dims = spec.Dimension;
catch
    dims = [11 1];
end

if isscalar(dims)
    dims = [dims 1];
end
dims = double(dims(:)');
end

function dimsText = localObservationDims(obs)
if iscell(obs)
    parts = strings(size(obs));
    for i = 1:numel(obs)
        parts(i) = "[" + strjoin(string(size(obs{i})), "x") + "]";
    end
    dimsText = strjoin(parts, ", ");
else
    dimsText = "[" + strjoin(string(size(obs)), "x") + "]";
end
end

function [obs, source] = localCreateObservationFromDatOrZero(datFile, obsTemplate)
obs = obsTemplate;
source = "zero observation from observation specification";

if iscell(obsTemplate)
    return;
end

targetNumel = numel(obsTemplate);

if exist(datFile, "file")
    D = readmatrix(datFile, ...
        "FileType", "text", ...
        "Delimiter", "\t", ...
        "CommentStyle", "%");

    if size(D, 2) < 14
        D = readmatrix(datFile, ...
            "FileType", "text", ...
            "CommentStyle", "%");
    end

    if ~isempty(D) && size(D, 2) >= 14
        sample = D(find(all(isfinite(D(:, 4:14)), 2), 1, "first"), 4:14);
        if numel(sample) == targetNumel
            obs = reshape(sample, size(obsTemplate));
            source = "dat file columns 4:14";
            return;
        end

        warning("dat observation columns 4:14 have %d values, but agent observation has %d values. Using zero observation.", ...
            numel(sample), targetNumel);
    else
        warning("dat file could not provide columns 4:14. Using zero observation.");
    end
else
    warning("dat file was not found. Using zero observation:\n%s", datFile);
end
end

function [actionFcn, description] = localSelectGetActionFunction(policyObj, obsNumeric)
obsCell = localEnsureCell(obsNumeric);

attempts = {
    @() getAction(policyObj, obsNumeric), "getAction(policyObj, obs)"
    @() getAction(policyObj, obsCell), "getAction(policyObj, {obs})"
    @() getAction(policyObj, {obsNumeric}), "getAction(policyObj, {obs}) explicit"
};

for i = 1:size(attempts, 1)
    f = attempts{i, 1};
    try
        f();
        actionFcn = f;
        description = attempts{i, 2};
        return;
    catch
    end
end

error("Could not call getAction with numeric observation or cell observation.");
end

function obsCell = localEnsureCell(obs)
if iscell(obs)
    obsCell = obs;
else
    obsCell = {obs};
end
end

function p = localPercentile(x, pct)
x = sort(x(:));
x = x(isfinite(x));

if isempty(x)
    p = NaN;
    return;
end

if isscalar(x)
    p = x;
    return;
end

pos = 1 + (numel(x) - 1) * pct / 100;
lo = floor(pos);
hi = ceil(pos);

if lo == hi
    p = x(lo);
else
    weight = pos - lo;
    p = (1 - weight) * x(lo) + weight * x(hi);
end
end
