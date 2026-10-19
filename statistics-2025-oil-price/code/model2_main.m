% 导入数据
data = [
    2010, 239.3, 87, 199.49, 1, 447, 0, 7, 5;
    2011, 253.6, 88.5, 203.89, 1.12, 475, 0, 7, 5;
    2012, 271, 89.8, 204.92, 1.12, 495, 0, 7, 5;
    2013, 282, 91.2, 209.03, 1.12, 518, 0, 7, 5;
    2014, 308, 93, 210.11, 1.4, 535, 0, 7, 5;
    2015, 335.5, 92.5, 199.69, 1.52, 555, 0, 9, 5;
    2016, 381, 92, 191.5, 1.52, 578, 0, 9, 5;
    2017, 420, 93.5, 191.95, 1.52, 605, 0, 9, 5;
    2018, 462, 94.8, 189.11, 1.52, 635, 0, 9, 5;
    2019, 506, 95.2, 191.01, 1.52, 675, 20, 9, 5;
    2020, 542.4, 94, 194.92, 1.52, 685, 25, 9, 5;
    2021, 513, 96.8, 198.98, 1.52, 690, 49, 10, 5;
    2022, 508.28, 99.8, 204.66, 1.52, 670, 56, 10, 5;
    2023, 563.99, 101, 208.91, 1.52, 710, 70, 10, 5;
    2024, 570.06, 102.5, 210, 1.52, 740, 92, 10, 5
];

% 提取原油进口量数据
oil_import = data(:, 2);

% 构造时间序列作为自变量
X = (1:length(oil_import))';  % 简单的时间序列

% 结构性突变检验（Chow检验）
breakpoint_candidates = [5, 10]; % 候选断点
h = zeros(size(breakpoint_candidates));
p = zeros(size(breakpoint_candidates));
stats = cell(size(breakpoint_candidates));

for i = 1:length(breakpoint_candidates)
    breakpoint = breakpoint_candidates(i);

    % 第一部分回归
    y1 = oil_import(1:breakpoint);
    X1 = X(1:breakpoint);
    [b1, ~, r1] = regress(y1, [ones(length(X1),1), X1]);

    % 第二部分回归
    y2 = oil_import(breakpoint+1:end);
    X2 = X(breakpoint+1:end);
    [b2, ~, r2] = regress(y2, [ones(length(X2),1), X2]);

    % 计算结构性突变的统计量
    residuals_diff = [r1; r2];
    F_stat = (var(r1) + var(r2)) / var(residuals_diff);  % F检验
    p(i) = 1 - fcdf(F_stat, 1, length(residuals_diff)-2);
    h(i) = p(i) < 0.05;  % 如果p值小于0.05，则表示结构性突变
end

% 确定阶段边界
if any(h == 1)
    disp('存在结构性突变');
    breakpoints = breakpoint_candidates(h == 1); % 选择所有显著的断点
else
    disp('不存在结构性突变');
    breakpoints = [5, 10]; % 手动设置阶段边界
end

% 可视化阶段边界
figure;
plot(X, oil_import, '-b', 'LineWidth', 2);
hold on;
for i = 1:length(breakpoints)
    plot(breakpoints(i), oil_import(breakpoints(i)), 'ro', 'MarkerSize', 8);
end
title('油价数据及结构性突变断点');
xlabel('时间');
ylabel('原油进口量');
legend('油价数据', '阶段断点');

% 划分数据
oil_import_1 = oil_import(1:breakpoints(1));
oil_import_2 = oil_import(breakpoints(1)+1:breakpoints(2));
oil_import_3 = oil_import(breakpoints(2)+1:end);

% ARIMA模型
model1 = arima(1,1,1);
model2 = arima(1,1,1);
model3 = arima(1,1,1);

fit1 = estimate(model1, oil_import_1);
fit2 = estimate(model2, oil_import_2);
fit3 = estimate(model3, oil_import_3);

% 预测
forecast1 = forecast(fit1, 5);
forecast2 = forecast(fit2, 5);
forecast3 = forecast(fit3, 5);

% 可视化ARIMA预测结果
figure;
hold on;
plot(1:length(oil_import_1), oil_import_1, '-b', 'LineWidth', 2);
plot(length(oil_import_1) + (1:5), forecast1, '-r', 'LineWidth', 2);
plot(length(oil_import_1) + (1:5), forecast2, '-g', 'LineWidth', 2);
plot(length(oil_import_1) + (1:5), forecast3, '-k', 'LineWidth', 2);
title('ARIMA模型预测');
xlabel('时间');
ylabel('原油进口量');
legend('实际数据', '预测阶段1', '预测阶段2', '预测阶段3');

% 整合转型因素
carbon_price = data(:, 7);          % 碳排放价格
renewable_support = data(:, 8);     % 可再生能源支持
geopolitical_factors = data(:, 9);  % 地缘政治因素

% 动态权重集成预测
weights = [0.3, 0.4, 0.3]; % 示例权重
integrated_forecast = weights(1) * forecast1 + weights(2) * forecast2 + weights(3) * forecast3;

% 可视化转型因素与预测的关系
figure;
subplot(3,1,1);
plot(X, carbon_price, '-b', 'LineWidth', 2);
title('碳排放价格 (CPI)');
xlabel('时间');
ylabel('碳排放价格');

subplot(3,1,2);
plot(X, renewable_support, '-r', 'LineWidth', 2);
title('可再生能源支持 (REI)');
xlabel('时间');
ylabel('可再生能源支持');

subplot(3,1,3);
plot(X, geopolitical_factors, '-g', 'LineWidth', 2);
title('地缘政治因素 (EVI)');
xlabel('时间');
ylabel('地缘政治因素');

% 调整后的预测
adjustment_factor = (carbon_price(end-4:end) + renewable_support(end-4:end) + geopolitical_factors(end-4:end)) / 3;
adjusted_forecast = integrated_forecast .* adjustment_factor;

% 三维立体可视化预测结果
[X3D, Y3D] = meshgrid(1:5, 1:3); % 生成网格数据
Z3D = [forecast1'; forecast2'; forecast3']; % 预测值转化为矩阵形式
figure;
surf(X3D, Y3D, Z3D, 'FaceColor', 'b');
xlabel('时间');
ylabel('阶段');
zlabel('预测的原油进口量');
title('调整后的油价预测 - 三维立体可视化');
colorbar;
