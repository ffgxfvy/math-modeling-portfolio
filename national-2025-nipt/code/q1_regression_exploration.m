
clear;
clc;
close all;

filePath = './data/问题一.xlsx'; 

 originalTable = readtable(filePath);
    
    disp('表格列名：');
    disp(originalTable.Properties.VariableNames);

    columnName = 'Var2'; 
    
    if ~ismember(columnName, originalTable.Properties.VariableNames)
        error('列名"%s"在表格中不存在，请查看上面的列名列表', columnName);
    end
    
    data = readtable(filePath);
    
    required_columns = {'Var2', 'Var3', 'Var4'};
    actual_columns = data.Properties.VariableNames;
    
    missing_columns = setdiff(required_columns, actual_columns);
    if ~isempty(missing_columns)
        error('Excel文件中缺少以下列: %s', strjoin(missing_columns, ', '));
    end
    
    gestational_week = data.Var2;
    BMI = data.Var3;
    Y_concentration = data.Var4;
    
    fprintf('成功从Excel文件读取数据\n');
    fprintf('数据大小: %d 行 × %d 列\n', size(data, 1), size(data, 2));
    

valid_indices = ~(isnan(gestational_week) | isnan(BMI) | isnan(Y_concentration));
gestational_week = gestational_week(valid_indices);
BMI = BMI(valid_indices);
Y_concentration = Y_concentration(valid_indices);


fprintf('\n=== 数据统计信息 ===\n');
fprintf('有效样本数量: %d\n', length(Y_concentration));
fprintf('孕周数范围: [%.1f, %.1f] 周\n', min(gestational_week), max(gestational_week));
fprintf('BMI范围: [%.2f, %.2f]\n', min(BMI), max(BMI));
fprintf('Y染色体浓度范围: [%.6f, %.6f]\n', min(Y_concentration), max(Y_concentration));
fprintf('Y染色体浓度均值: %.6f\n', mean(Y_concentration));
fprintf('Y染色体浓度标准差: %.6f\n', std(Y_concentration));

figure('Position', [100, 100, 1200, 400], 'Name', '数据分布可视化');
subplot(1,3,1);
scatter(gestational_week, Y_concentration, 50, 'filled', 'MarkerFaceColor', [0.2 0.4 0.6]);
xlabel('孕周数 (周)');
ylabel('Y染色体浓度');
title('Y染色体浓度 vs 孕周数');
grid on;

subplot(1,3,2);
scatter(BMI, Y_concentration, 50, 'filled', 'MarkerFaceColor', [0.6 0.2 0.4]);
xlabel('BMI');
ylabel('Y染色体浓度');
title('Y染色体浓度 vs BMI');
grid on;

subplot(1,3,3);
scatter3(gestational_week, BMI, Y_concentration, 60, Y_concentration, 'filled');
xlabel('孕周数 (周)');
ylabel('BMI');
zlabel('Y染色体浓度');
title('三维散点图 - Y染色体浓度分布');
colorbar;
colormap jet;
grid on;


model = @(b, x) b(1)*exp(b(2)*x(:,2)) + b(3)*exp(b(4)*x(:,1));

x_data = [gestational_week, BMI];

initial_params = [0.001, 0.1, 0.001, 0.01];

fprintf('\n=== 开始非线性拟合 ===\n');
options = statset('Display','final','MaxIter',1000,'TolFun',1e-8,'TolX',1e-8);
[beta, R, J, CovB, MSE] = nlinfit(x_data, Y_concentration, model, initial_params, options);

Y_pred = model(beta, x_data);

SS_res = sum(R.^2);
SS_tot = sum((Y_concentration - mean(Y_concentration)).^2);
R_squared = 1 - SS_res / SS_tot;

n = length(Y_concentration);
p = length(beta);
adj_R_squared = 1 - (SS_res/(n-p)) / (SS_tot/(n-1));

ci = nlparci(beta, R, 'Jacobian', J);
std_err = (ci(:,2) - ci(:,1)) / (2 * tinv(0.975, n-p));

fprintf('\n=== 双指数函数拟合结果 ===\n');
fprintf('模型: Y = a * exp(b * BMI) + c * exp(d * GestationalWeek)\n\n');
fprintf('参数估计 (带95%%置信区间):\n');
fprintf('a = %.6f ± %.6f (95%% CI: [%.6f, %.6f])\n', beta(1), std_err(1), ci(1,1), ci(1,2));
fprintf('b = %.6f ± %.6f (95%% CI: [%.6f, %.6f])\n', beta(2), std_err(2), ci(2,1), ci(2,2));
fprintf('c = %.6f ± %.6f (95%% CI: [%.6f, %.6f])\n', beta(3), std_err(3), ci(3,1), ci(3,2));
fprintf('d = %.6f ± %.6f (95%% CI: [%.6f, %.6f])\n', beta(4), std_err(4), ci(4,1), ci(4,2));
fprintf('\n');

fprintf('模型评估指标:\n');
fprintf('决定系数 R² = %.4f\n', R_squared);
fprintf('调整决定系数 调整R² = %.4f\n', adj_R_squared);
fprintf('均方误差 (MSE) = %.8f\n', MSE);
fprintf('残差平方和 (SS_res) = %.8f\n', SS_res);
fprintf('总平方和 (SS_tot) = %.8f\n', SS_tot);
fprintf('样本数量 n = %d\n', n);
fprintf('参数数量 p = %d\n', p);

figure('Position', [100, 100, 800, 600], 'Name', '双指数函数拟合曲面');

gw_range = linspace(min(gestational_week), max(gestational_week), 25);
bmi_range = linspace(min(BMI), max(BMI), 25);
[GW_grid, BMI_grid] = meshgrid(gw_range, bmi_range);

Y_grid = beta(1)*exp(beta(2)*BMI_grid) + beta(3)*exp(beta(4)*GW_grid);


surf(GW_grid, BMI_grid, Y_grid, 'FaceAlpha', 0.7, 'EdgeColor', 'none');
hold on;
scatter3(gestational_week, BMI, Y_concentration, 80, 'r', 'filled', 'MarkerEdgeColor', 'k');
hold off;

xlabel('孕周数 (周)');
ylabel('BMI');
zlabel('Y染色体浓度预测值');
title('双指数函数拟合曲面');
legend('拟合曲面', '原始数据点', 'Location', 'best');
grid on;
colormap jet;
colorbar;

figure('Position', [100, 100, 1200, 400], 'Name', '残差分析');

subplot(1,3,1);
plot(Y_pred, R, 'o', 'MarkerSize', 8, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k');
hold on;
plot([min(Y_pred), max(Y_pred)], [0, 0], 'r--', 'LineWidth', 2);
xlabel('预测值');
ylabel('残差');
title('残差 vs 预测值');
grid on;

subplot(1,3,2);
normplot(R);
title('残差正态概率图');
grid on;

subplot(1,3,3);
scatter(gestational_week, R, 50, 'filled', 'MarkerFaceColor', [0.5 0.2 0.8]);
hold on;
plot([min(gestational_week), max(gestational_week)], [0, 0], 'r--', 'LineWidth', 2);
xlabel('孕周数');
ylabel('残差');
title('残差 vs 孕周数');
grid on;

figure('Position', [100, 100, 600, 500], 'Name', '预测值与实际值比较');
plot(Y_concentration, Y_pred, 'o', 'MarkerSize', 8, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k');
hold on;
plot([min(Y_concentration), max(Y_concentration)], [min(Y_concentration), max(Y_concentration)], 'r--', 'LineWidth', 2);
xlabel('实际Y染色体浓度');
ylabel('预测Y染色体浓度');
title('预测值 vs 实际值');
axis equal;
grid on;

corr_coef = corr(Y_concentration, Y_pred);
fprintf('\n预测值与实际值的相关系数: %.4f\n', corr_coef);

fprintf('\n=== 最终拟合方程 ===\n');
fprintf('Y_concentration = %.6f * exp(%.6f * BMI) + %.6f * exp(%.6f * GestationalWeek)\n', ...
        beta(1), beta(2), beta(3), beta(4));

fprintf('\n正在保存结果到Excel文件...\n');
try

    results_table = table(gestational_week, BMI, Y_concentration, Y_pred, R, ...
        'VariableNames', {'GestationalWeek', 'BMI', 'Actual_Y', 'Predicted_Y', 'Residuals'});
    
    output_filename = 'NIPT_Analysis_Results.xlsx';
    writetable(results_table, output_filename);
    fprintf('结果已保存到: %s\n', output_filename);
    
catch
    fprintf('保存结果文件失败\n');
end

fprintf('\n=== 分析完成 ===\n');