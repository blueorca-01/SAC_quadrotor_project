clc; clear;

%% =========================================================
%% 0) 파일 경로
%% =========================================================
rootDir = "result";
datRoot = fullfile(rootDir, "실험 결과 dat 파일 모음");

fname = "No Agent(mod_1)";   % 실험명
datDir = fullfile(datRoot, fname);

dataFile = fullfile(datDir, fname + "_all_runs.dat");

%% =========================================================
%% 1) 데이터 불러오기
%% =========================================================
D = readmatrix(dataFile);

% case 1만 선택
idx = (D(:,2) == 1);
D = D(idx, :);


% 열 분리
runID = D(:,1);
casenum  = D(:,2);
t     = D(:,3);

x     = D(:,4);
y     = D(:,5);
z     = D(:,6);

e_v_dir    = D(:,7);
e_v_mag    = D(:,8);

phi   = D(:,9);
theta = D(:,10);
psi   = D(:,11);

p     = D(:,12);
q     = D(:,13);
r     = D(:,14);

%% =========================================================
%% 2) 변수별 robust 통계 계산
%% =========================================================
calcStats = @(v) localRobustStats(v);

sx     = calcStats(x);
sy     = calcStats(y);
sz     = calcStats(z);

sevdir    = calcStats(e_v_dir);
sevmag    = calcStats(e_v_mag);

sphi   = calcStats(phi);
stheta = calcStats(theta);
spsi   = calcStats(psi);

sp     = calcStats(p);
sq     = calcStats(q);
sr     = calcStats(r);

%% =========================================================
%% 3) 표 형태로 정리
%% =========================================================
varName = ["x"; "y"; "z"; ...
           "e_v_dir"; "e_v_mag"; ...
           "phi"; "theta"; "psi"; ...
           "p"; "q"; "r"];

medianVal = [
    sx.median;
    sy.median;
    sz.median;
    sevdir.median;
    sevmag.median;
    sphi.median;
    stheta.median;
    spsi.median;
    sp.median;
    sq.median;
    sr.median
];

MADVal = [
    sx.MAD;
    sy.MAD;
    sz.MAD;
    sevdir.MAD;
    sevmag.MAD;
    sphi.MAD;
    stheta.MAD;
    spsi.MAD;
    sp.MAD;
    sq.MAD;
    sr.MAD
];

robustScale = [
    sx.robustScale;
    sy.robustScale;
    sz.robustScale;
    sevdir.robustScale;
    sevmag.robustScale;
    sphi.robustScale;
    stheta.robustScale;
    spsi.robustScale;
    sp.robustScale;
    sq.robustScale;
    sr.robustScale
];

deltaHuber = [
    sx.delta;
    sy.delta;
    sz.delta;
    sevdir.delta;
    sevmag.delta;
    sphi.delta;
    stheta.delta;
    spsi.delta;
    sp.delta;
    sq.delta;
    sr.delta
];

T = table(varName, medianVal, MADVal, robustScale, deltaHuber, ...
    'VariableNames', {'Variable', 'Median', 'MAD', 'RobustScale', 'HuberDelta'});

disp(T);

%% =========================================================
%% 4) txt 저장
%% =========================================================
outFile = fullfile(datDir, fname + "_delta_summary.txt");
fid = fopen(outFile, 'w');

fprintf(fid, "Variable\tMedian\tMAD\tRobustScale\tHuberDelta\n");
for i = 1:height(T)
    fprintf(fid, "%s\t%.10f\t%.10f\t%.10f\t%.10f\n", ...
        T.Variable(i), T.Median(i), T.MAD(i), T.RobustScale(i), T.HuberDelta(i));
end

fclose(fid);

disp("delta summary 저장 완료");

%% =========================================================
%% Local Function
%% =========================================================
function S = localRobustStats(v)

    v = double(v(:));
    v = v(~isnan(v));

    medv = median(v, 'omitnan');
    madv = median(abs(v - medv), 'omitnan');

    robustScale = madv / 0.6745;
    delta = 1.345 * robustScale;

    S.median = medv;
    S.MAD = madv;
    S.robustScale = robustScale;
    S.delta = delta;
end