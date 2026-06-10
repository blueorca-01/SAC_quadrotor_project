%statstical.m

clc; clear; close all;

fname = "(Huber)SAC_ver3(mod_1)";

rootDir = "result";
expDir = fullfile(rootDir, "실험 결과 dat 파일 모음");
datDir = fullfile(expDir, fname);
expdata = fullfile(datDir, fname + "_all_runs.dat");

D = readmatrix(expdata);

runID = D(:,1);
caseNum = D(:,2);
t = D(:,3);
x = D(:,4);
y = D(:,5);
z = D(:,6);
e_v_dir = D(:,7);
e_v_mag = D(:,8);
phi = D(:,9);
theta = D(:,10);
psi = D(:,11);
p = D(:,12);
q = D(:,13);
r = D(:,14); 
ATH1 = D(:,15);
ATH2 = D(:,16);
ATH3 = D(:,17);
ATH4 = D(:,18);
TTH1 = D(:,19);
TTH2 = D(:,20);
TTH3 = D(:,21);
TTH4 = D(:,22);

e_posh = sqrt(x.^2 + y.^2);
e_pos3D = sqrt(x.^2 + y.^2 + z.^2);
e_attRP = sqrt(phi.^2 + theta.^2);
e_omega = sqrt(phi.^2 + theta.^2 + psi.^2);

runs = length(unique(runID));
cases = length(unique(caseNum));
steps = length(unique(t));

MAE = zeros(runs, cases,11);
RMSE = zeros(runs, cases,11);
complex_MAE = zeros(runs, cases, 4);
complex_RMSE = zeros(runs, cases, 4);

for c = 1:cases
    for i = 1:runs
        idx = (caseNum == c) & (runID == i);
    
        MAE(i,c,1) = mean(abs(x(idx)),"omitnan");
        MAE(i,c,2) = mean(abs(y(idx)),"omitnan");
        MAE(i,c,3) = mean(abs(z(idx)),"omitnan");
        MAE(i,c,4) = mean(abs(e_v_dir(idx)),"omitnan");
        MAE(i,c,5) = mean(abs(e_v_mag(idx)),"omitnan");
        MAE(i,c,6) = mean(abs(phi(idx)),"omitnan");
        MAE(i,c,7) = mean(abs(theta(idx)),"omitnan");
        MAE(i,c,8) = mean(abs(psi(idx)),"omitnan");
        MAE(i,c,9) = mean(abs(p(idx)),"omitnan");
        MAE(i,c,10) = mean(abs(q(idx)),"omitnan");
        MAE(i,c,11) = mean(abs(r(idx)),"omitnan");
        
        complex_MAE(i,c,1) = mean(abs(e_posh(idx)),"omitnan");
        complex_MAE(i,c,2) = mean(abs(e_pos3D(idx)),"omitnan");
        complex_MAE(i,c,3) = mean(abs(e_attRP(idx)),"omitnan");
        complex_MAE(i,c,4) = mean(abs(e_omega(idx)),"omitnan");
    
        RMSE(i,c,1)  = sqrt(mean(x(idx).^2, "omitnan"));
        RMSE(i,c,2)  = sqrt(mean(y(idx).^2, "omitnan"));
        RMSE(i,c,3)  = sqrt(mean(z(idx).^2, "omitnan"));
        RMSE(i,c,4)  = sqrt(mean(e_v_dir(idx).^2, "omitnan"));
        RMSE(i,c,5)  = sqrt(mean(e_v_mag(idx).^2, "omitnan"));
        RMSE(i,c,6)  = sqrt(mean(phi(idx).^2, "omitnan"));
        RMSE(i,c,7)  = sqrt(mean(theta(idx).^2, "omitnan"));
        RMSE(i,c,8)  = sqrt(mean(psi(idx).^2, "omitnan"));
        RMSE(i,c,9)  = sqrt(mean(p(idx).^2, "omitnan"));
        RMSE(i,c,10) = sqrt(mean(q(idx).^2, "omitnan"));
        RMSE(i,c,11) = sqrt(mean(r(idx).^2, "omitnan"));
        
        complex_RMSE(i,c,1) = sqrt(mean(e_posh(idx).^2, "omitnan"));
        complex_RMSE(i,c,2) = sqrt(mean(e_pos3D(idx).^2, "omitnan"));
        complex_RMSE(i,c,3) = sqrt(mean(e_attRP(idx).^2, "omitnan"));
        complex_RMSE(i,c,4) = sqrt(mean(e_omega(idx).^2, "omitnan"));
    
    end
end

MAE_mean = zeros(cases, 11);
MAE_std  = zeros(cases, 11);
MAE_max  = zeros(cases, 11);

for c = 1:cases
    temp = squeeze(MAE(:, c, :));   % runs x 11

    MAE_mean(c, :) = mean(temp, 1, "omitnan");
    MAE_std(c, :)  = std(temp, 0, 1, "omitnan");
    MAE_max(c, :)  = max(temp, [], 1);
end

varName = ["x"; "y"; "z"; ...
           "e_v_dir"; "e_v_mag"; ...
           "phi"; "theta"; "psi"; ...
           "p"; "q"; "r"];

T_MAE = table( ...
    varName, ...
    MAE_mean(1,:)', MAE_std(1,:)', MAE_max(1,:)', ...
    MAE_mean(2,:)', MAE_std(2,:)', MAE_max(2,:)', ...
    MAE_mean(3,:)', MAE_std(3,:)', MAE_max(3,:)', ...
    MAE_mean(4,:)', MAE_std(4,:)', MAE_max(4,:)', ...
    'VariableNames', {'Variable', ...
    'Mean_case1', 'Std_case1', 'Max_case1', ...
    'Mean_case2', 'Std_case2', 'Max_case2', ...
    'Mean_case3', 'Std_case3', 'Max_case3', ...
    'Mean_case4', 'Std_case4', 'Max_case4'});

fprintf("=================================\n");
fprintf("        %s\n", fname);
fprintf("=================================\n");
fprintf("\n======MAE======\n");
disp(T_MAE)

RMSE_mean = zeros(cases, 11);
RMSE_std  = zeros(cases, 11);
RMSE_max  = zeros(cases, 11);

for c = 1:cases
    temp = squeeze(RMSE(:, c, :));   % runs x 11

    RMSE_mean(c, :) = mean(temp, 1, "omitnan");
    RMSE_std(c, :)  = std(temp, 0, 1, "omitnan");
    RMSE_max(c, :)  = max(temp, [], 1);
end

varName = ["x"; "y"; "z"; ...
           "e_v_dir"; "e_v_mag"; ...
           "phi"; "theta"; "psi"; ...
           "p"; "q"; "r"];

T_RMSE = table( ...
    varName, ...
    RMSE_mean(1,:)', RMSE_std(1,:)', RMSE_max(1,:)', ...
    RMSE_mean(2,:)', RMSE_std(2,:)', RMSE_max(2,:)', ...
    RMSE_mean(3,:)', RMSE_std(3,:)', RMSE_max(3,:)', ...
    RMSE_mean(4,:)', RMSE_std(4,:)', RMSE_max(4,:)', ...
    'VariableNames', {'Variable', ...
    'Mean_case1', 'Std_case1', 'Max_case1', ...
    'Mean_case2', 'Std_case2', 'Max_case2', ...
    'Mean_case3', 'Std_case3', 'Max_case3', ...
    'Mean_case4', 'Std_case4', 'Max_case4'});

fprintf("\n======RMSE======\n");
disp(T_RMSE)

Complex_MAE_mean = zeros(cases, 4);
Complex_MAE_std  = zeros(cases, 4);
Complex_MAE_max  = zeros(cases, 4);

for c = 1:cases
    temp = squeeze(complex_MAE(:, c, :));   % runs x 4

    Complex_MAE_mean(c, :) = mean(temp, 1, "omitnan");
    Complex_MAE_std(c, :)  = std(temp, 0, 1, "omitnan");
    Complex_MAE_max(c, :)  = max(temp, [], 1);
end

varName = ["e_posh"; "e_pos3D"; "e_attRP"; "e_attRPY"];

T_Complex_MAE = table( ...
    varName, ...
    Complex_MAE_mean(1,:)', Complex_MAE_std(1,:)', Complex_MAE_max(1,:)', ...
    Complex_MAE_mean(2,:)', Complex_MAE_std(2,:)', Complex_MAE_max(2,:)', ...
    Complex_MAE_mean(3,:)', Complex_MAE_std(3,:)', Complex_MAE_max(3,:)', ...
    Complex_MAE_mean(4,:)', Complex_MAE_std(4,:)', Complex_MAE_max(4,:)', ...
    'VariableNames', {'Variable', ...
    'Mean_case1', 'Std_case1', 'Max_case1', ...
    'Mean_case2', 'Std_case2', 'Max_case2', ...
    'Mean_case3', 'Std_case3', 'Max_case3', ...
    'Mean_case4', 'Std_case4', 'Max_case4'});

fprintf("\n======Complex MAE======\n");
disp(T_Complex_MAE)



% Complex_MAE_mean = mean(complex_MAE, 1, "omitnan");
% Complex_MAE_std = std(complex_MAE, 0, 1, "omitnan");
% Complex_MAE_max = max(complex_MAE, [], 1);
% 
% varName = ["e_posh"; "e_pos3D"; "e_attRP"; "e_omega"];
% 
% T_Complex_MAE = table(varName, Complex_MAE_mean(:), Complex_MAE_std(:), Complex_MAE_max(:), ...
%     'VariableNames', {'Variable', 'Mean', 'Std', 'Max'});
% 
% fprintf("\n======Complex MAE======\n");
% disp(T_Complex_MAE)

Complex_RMSE_mean = zeros(cases, 4);
Complex_RMSE_std  = zeros(cases, 4);
Complex_RMSE_max  = zeros(cases, 4);

for c = 1:cases
    temp = squeeze(complex_RMSE(:, c, :));   % runs x 4

    Complex_RMSE_mean(c, :) = mean(temp, 1, "omitnan");
    Complex_RMSE_std(c, :)  = std(temp, 0, 1, "omitnan");
    Complex_RMSE_max(c, :)  = max(temp, [], 1);
end

varName = ["e_posh"; "e_pos3D"; "e_attRP"; "e_attRPY"];

T_Complex_RMSE = table( ...
    varName, ...
    Complex_RMSE_mean(1,:)', Complex_RMSE_std(1,:)', Complex_RMSE_max(1,:)', ...
    Complex_RMSE_mean(2,:)', Complex_RMSE_std(2,:)', Complex_RMSE_max(2,:)', ...
    Complex_RMSE_mean(3,:)', Complex_RMSE_std(3,:)', Complex_RMSE_max(3,:)', ...
    Complex_RMSE_mean(4,:)', Complex_RMSE_std(4,:)', Complex_RMSE_max(4,:)', ...
    'VariableNames', {'Variable', ...
    'Mean_case1', 'Std_case1', 'Max_case1', ...
    'Mean_case2', 'Std_case2', 'Max_case2', ...
    'Mean_case3', 'Std_case3', 'Max_case3', ...
    'Mean_case4', 'Std_case4', 'Max_case4',});

fprintf("\n======Complex RMSE======\n");
disp(T_Complex_RMSE)