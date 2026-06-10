% statistical_comp.m - Comparative Analysis with No Agent as Baseline
% Compares two agents' Complex RMSE and Complex MAE against No Agent baseline

clc; clear; close all;

% ========================================
% 1. Load baseline data (No Agent)
% ========================================
fname_baseline = "No Agent(mod_1)";
rootDir = "result";
expDir = fullfile(rootDir, "실험 결과 dat 파일 모음");
datDir_base = fullfile(expDir, fname_baseline);
expdata_base = fullfile(datDir_base, fname_baseline + "_all_runs.dat");

% ========================================
% 2. Set comparison file
% ========================================
% Specify the filename to compare with baseline
fname_compare = "(Revised)TD3_ver1(mod_1)";  % Change this line to your comparison file
datDir_comp = fullfile(expDir, fname_compare);
expdata_comp = fullfile(datDir_comp, fname_compare + "_all_runs.dat");

if ~isfile(expdata_comp)
    error("File not found: " + expdata_comp);
end

D_base = readmatrix(expdata_base);

runID_base = D_base(:,1);
caseNum_base = D_base(:,2);
t_base = D_base(:,3);
x_base = D_base(:,4);
y_base = D_base(:,5);
z_base = D_base(:,6);
e_v_dir_base = D_base(:,7);
e_v_mag_base = D_base(:,8);
phi_base = D_base(:,9);
theta_base = D_base(:,10);
psi_base = D_base(:,11);
p_base = D_base(:,12);
q_base = D_base(:,13);
r_base = D_base(:,14);

% Calculate complex errors for baseline
e_posh_base = sqrt(x_base.^2 + y_base.^2);
e_pos3D_base = sqrt(x_base.^2 + y_base.^2 + z_base.^2);
e_attRP_base = sqrt(phi_base.^2 + theta_base.^2);
e_attRPY_base = sqrt(phi_base.^2 + theta_base.^2 + psi_base.^2);

runs_base = length(unique(runID_base));
cases_base = length(unique(caseNum_base));

% Calculate metrics for baseline
complex_MAE_base = zeros(runs_base, cases_base, 4);
complex_RMSE_base = zeros(runs_base, cases_base, 4);
angular_RMSE_base = zeros(runs_base, cases_base, 3);

for c = 1:cases_base
    for i = 1:runs_base
        idx = (caseNum_base == c) & (runID_base == i);
        
        complex_MAE_base(i,c,1) = mean(abs(e_posh_base(idx)),"omitnan");
        complex_MAE_base(i,c,2) = mean(abs(e_pos3D_base(idx)),"omitnan");
        complex_MAE_base(i,c,3) = mean(abs(e_attRP_base(idx)),"omitnan");
        complex_MAE_base(i,c,4) = mean(abs(e_attRPY_base(idx)),"omitnan");
        
        complex_RMSE_base(i,c,1) = sqrt(mean(e_posh_base(idx).^2, "omitnan"));
        complex_RMSE_base(i,c,2) = sqrt(mean(e_pos3D_base(idx).^2, "omitnan"));
        complex_RMSE_base(i,c,3) = sqrt(mean(e_attRP_base(idx).^2, "omitnan"));
        complex_RMSE_base(i,c,4) = sqrt(mean(e_attRPY_base(idx).^2, "omitnan"));

        angular_RMSE_base(i,c,1) = sqrt(mean(p_base(idx).^2, "omitnan"));
        angular_RMSE_base(i,c,2) = sqrt(mean(q_base(idx).^2, "omitnan"));
        angular_RMSE_base(i,c,3) = sqrt(mean(r_base(idx).^2, "omitnan"));
    end
end

% Calculate mean and std for baseline
Complex_MAE_mean_base = zeros(cases_base, 4);
Complex_MAE_std_base = zeros(cases_base, 4);
Complex_RMSE_mean_base = zeros(cases_base, 4);
Complex_RMSE_std_base = zeros(cases_base, 4);
Angular_RMSE_mean_base = zeros(cases_base, 3);
Angular_RMSE_std_base = zeros(cases_base, 3);

for c = 1:cases_base
    temp_mae = squeeze(complex_MAE_base(:, c, :));
    temp_rmse = squeeze(complex_RMSE_base(:, c, :));
    
    Complex_MAE_mean_base(c, :) = mean(temp_mae, 1, "omitnan");
    Complex_MAE_std_base(c, :) = std(temp_mae, 0, 1, "omitnan");
    Complex_RMSE_mean_base(c, :) = mean(temp_rmse, 1, "omitnan");
    Complex_RMSE_std_base(c, :) = std(temp_rmse, 0, 1, "omitnan");

    temp_angular_rmse = reshape(angular_RMSE_base(:, c, :), runs_base, 3);
    Angular_RMSE_mean_base(c, :) = mean(temp_angular_rmse, 1, "omitnan");
    Angular_RMSE_std_base(c, :) = std(temp_angular_rmse, 0, 1, "omitnan");
end



% ========================================
% 3. Load comparison data
% ========================================


D_comp = readmatrix(expdata_comp);

runID_comp = D_comp(:,1);
caseNum_comp = D_comp(:,2);
t_comp = D_comp(:,3);
x_comp = D_comp(:,4);
y_comp = D_comp(:,5);
z_comp = D_comp(:,6);
e_v_dir_comp = D_comp(:,7);
e_v_mag_comp = D_comp(:,8);
phi_comp = D_comp(:,9);
theta_comp = D_comp(:,10);
psi_comp = D_comp(:,11);
p_comp = D_comp(:,12);
q_comp = D_comp(:,13);
r_comp = D_comp(:,14);

% Calculate complex errors for comparison
e_posh_comp = sqrt(x_comp.^2 + y_comp.^2);
e_pos3D_comp = sqrt(x_comp.^2 + y_comp.^2 + z_comp.^2);
e_attRP_comp = sqrt(phi_comp.^2 + theta_comp.^2);
e_attRPY_comp = sqrt(phi_comp.^2 + theta_comp.^2 + psi_comp.^2);

runs_comp = length(unique(runID_comp));
cases_comp = length(unique(caseNum_comp));

% Calculate metrics for comparison
complex_MAE_comp = zeros(runs_comp, cases_comp, 4);
complex_RMSE_comp = zeros(runs_comp, cases_comp, 4);
angular_RMSE_comp = zeros(runs_comp, cases_comp, 3);

for c = 1:cases_comp
    for i = 1:runs_comp
        idx = (caseNum_comp == c) & (runID_comp == i);
        
        complex_MAE_comp(i,c,1) = mean(abs(e_posh_comp(idx)),"omitnan");
        complex_MAE_comp(i,c,2) = mean(abs(e_pos3D_comp(idx)),"omitnan");
        complex_MAE_comp(i,c,3) = mean(abs(e_attRP_comp(idx)),"omitnan");
        complex_MAE_comp(i,c,4) = mean(abs(e_attRPY_comp(idx)),"omitnan");
        
        complex_RMSE_comp(i,c,1) = sqrt(mean(e_posh_comp(idx).^2, "omitnan"));
        complex_RMSE_comp(i,c,2) = sqrt(mean(e_pos3D_comp(idx).^2, "omitnan"));
        complex_RMSE_comp(i,c,3) = sqrt(mean(e_attRP_comp(idx).^2, "omitnan"));
        complex_RMSE_comp(i,c,4) = sqrt(mean(e_attRPY_comp(idx).^2, "omitnan"));

        angular_RMSE_comp(i,c,1) = sqrt(mean(p_comp(idx).^2, "omitnan"));
        angular_RMSE_comp(i,c,2) = sqrt(mean(q_comp(idx).^2, "omitnan"));
        angular_RMSE_comp(i,c,3) = sqrt(mean(r_comp(idx).^2, "omitnan"));
    end
end

% Calculate mean and std for comparison
Complex_MAE_mean_comp = zeros(cases_comp, 4);
Complex_MAE_std_comp = zeros(cases_comp, 4);
Complex_RMSE_mean_comp = zeros(cases_comp, 4);
Complex_RMSE_std_comp = zeros(cases_comp, 4);
Angular_RMSE_mean_comp = zeros(cases_comp, 3);
Angular_RMSE_std_comp = zeros(cases_comp, 3);

for c = 1:cases_comp
    temp_mae = squeeze(complex_MAE_comp(:, c, :));
    temp_rmse = squeeze(complex_RMSE_comp(:, c, :));
    
    Complex_MAE_mean_comp(c, :) = mean(temp_mae, 1, "omitnan");
    Complex_MAE_std_comp(c, :) = std(temp_mae, 0, 1, "omitnan");
    Complex_RMSE_mean_comp(c, :) = mean(temp_rmse, 1, "omitnan");
    Complex_RMSE_std_comp(c, :) = std(temp_rmse, 0, 1, "omitnan");

    temp_angular_rmse = reshape(angular_RMSE_comp(:, c, :), runs_comp, 3);
    Angular_RMSE_mean_comp(c, :) = mean(temp_angular_rmse, 1, "omitnan");
    Angular_RMSE_std_comp(c, :) = std(temp_angular_rmse, 0, 1, "omitnan");
end

% ========================================
% 4. Calculate relative improvement (% reduction from baseline)
% ========================================
% Improvement = (Baseline - Comparison) / Baseline * 100 (positive = improvement)

min_cases = min(cases_base, cases_comp);

% For MAE
MAE_improvement_mean = zeros(min_cases, 4);  % percentage improvement
MAE_improvement_std = zeros(min_cases, 4);

for c = 1:min_cases
    for m = 1:4
        if Complex_MAE_mean_base(c, m) > 0
            MAE_improvement_mean(c, m) = (Complex_MAE_mean_base(c, m) - Complex_MAE_mean_comp(c, m)) / Complex_MAE_mean_base(c, m) * 100;
        end
    end
end

% For RMSE
RMSE_improvement_mean = zeros(min_cases, 4);  % percentage improvement
RMSE_improvement_std = zeros(min_cases, 4);

for c = 1:min_cases
    for m = 1:4
        if Complex_RMSE_mean_base(c, m) > 0
            RMSE_improvement_mean(c, m) = (Complex_RMSE_mean_base(c, m) - Complex_RMSE_mean_comp(c, m)) / Complex_RMSE_mean_base(c, m) * 100;
        end
    end
end

% For angular-rate RMSE
Angular_RMSE_improvement_mean = zeros(min_cases, 3);

for c = 1:min_cases
    for m = 1:3
        if Angular_RMSE_mean_base(c, m) > 0
            Angular_RMSE_improvement_mean(c, m) = (Angular_RMSE_mean_base(c, m) - Angular_RMSE_mean_comp(c, m)) / Angular_RMSE_mean_base(c, m) * 100;
        end
    end
end

% ========================================
% 5. Display comparative results
% ========================================
fprintf("\n========================================\n");
fprintf("Baseline: %s\n", fname_baseline);
fprintf("Compare:  %s\n", fname_compare);
fprintf("========================================\n\n");

% Create column names with actual filenames
baseline_col_name = sprintf("%s (Mean)", fname_baseline);
compare_col_name = sprintf("%s (Mean)", fname_compare);

% Metric names for tables
metric_names = ["e_posh"; "e_pos3D"; "e_attRP"; "e_attRPY"];
metric_descriptions = [...
    "수평 평면에서의 위치 오차 (X-Y)"; ...
    "3차원 공간에서의 위치 오차 (X-Y-Z)"; ...
    "Roll과 Pitch 자세 각도 오차"; ...
    "Roll, Pitch, Yaw 자세 각도 오차"];

% ========================================
% Create separate tables for each metric (MAE)
% ========================================
fprintf("======Complex MAE (평균 절대 오차)======\n");
fprintf("각 메트릭별로 절대 오차의 평균값을 나타냅니다.\n\n");

for m = 1:4
    mae_case_data = [];
    mae_baseline_data = [];
    mae_compare_data = [];
    mae_improve_data = [];
    
    for c = 1:min_cases
        mae_case_data = [mae_case_data; c];
        mae_baseline_data = [mae_baseline_data; Complex_MAE_mean_base(c, m)];
        mae_compare_data = [mae_compare_data; Complex_MAE_mean_comp(c, m)];
        mae_improve_data = [mae_improve_data; MAE_improvement_mean(c, m)];
    end
    
    T_MAE = table(mae_case_data, mae_baseline_data, mae_compare_data, mae_improve_data, ...
        'VariableNames', ["Case", string(baseline_col_name), string(compare_col_name), "Improvement (%)"]);
    
    fprintf("--- %s ---\n", metric_names(m));
    fprintf("%s\n", metric_descriptions(m));
    disp(T_MAE)
    fprintf("\n");
end

% ========================================
% Create separate tables for each metric (RMSE)
% ========================================
fprintf("\n======Complex RMSE (평균 제곱근 오차)======\n");
fprintf("각 메트릭별로 제곱근 평균 제곱 오차를 나타냅니다.\n\n");

for m = 1:4
    rmse_case_data = [];
    rmse_baseline_data = [];
    rmse_compare_data = [];
    rmse_improve_data = [];
    
    for c = 1:min_cases
        rmse_case_data = [rmse_case_data; c];
        rmse_baseline_data = [rmse_baseline_data; Complex_RMSE_mean_base(c, m)];
        rmse_compare_data = [rmse_compare_data; Complex_RMSE_mean_comp(c, m)];
        rmse_improve_data = [rmse_improve_data; RMSE_improvement_mean(c, m)];
    end
    
    T_RMSE = table(rmse_case_data, rmse_baseline_data, rmse_compare_data, rmse_improve_data, ...
        'VariableNames', ["Case", string(baseline_col_name), string(compare_col_name), "Improvement (%)"]);
    
    fprintf("--- %s ---\n", metric_names(m));
    fprintf("%s\n", metric_descriptions(m));
    disp(T_RMSE)
    fprintf("\n");
end

% ========================================
% Create separate tables for angular-rate RMSE
% ========================================
angular_rate_names = ["p"; "q"; "r"];

fprintf("\n======3-Axis Angular Rate RMSE======\n");
fprintf("p, q, r angular-rate RMSE comparison by case.\n\n");

for m = 1:3
    angular_case_data = [];
    angular_baseline_data = [];
    angular_compare_data = [];
    angular_improve_data = [];

    for c = 1:min_cases
        angular_case_data = [angular_case_data; c];
        angular_baseline_data = [angular_baseline_data; Angular_RMSE_mean_base(c, m)];
        angular_compare_data = [angular_compare_data; Angular_RMSE_mean_comp(c, m)];
        angular_improve_data = [angular_improve_data; Angular_RMSE_improvement_mean(c, m)];
    end

    T_Angular_RMSE = table(angular_case_data, angular_baseline_data, angular_compare_data, angular_improve_data, ...
        'VariableNames', ["Case", string(baseline_col_name), string(compare_col_name), "Improvement (%)"]);

    fprintf("--- %s angular-rate RMSE ---\n", angular_rate_names(m));
    disp(T_Angular_RMSE)
    fprintf("\n");
end

% ========================================
% 6. Summary statistics
% ========================================
fprintf("\n======SUMMARY======\n");
fprintf("Total improvement cases: %d\n", sum(sum(MAE_improvement_mean > 0)));
fprintf("Total degradation cases: %d\n", sum(sum(MAE_improvement_mean < 0)));
fprintf("Average improvement (MAE): %.2f%%\n", mean(mean(MAE_improvement_mean(MAE_improvement_mean > 0))));
fprintf("Average improvement (RMSE): %.2f%%\n", mean(mean(RMSE_improvement_mean(RMSE_improvement_mean > 0))));
