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
    [h(i), p(i), stats{i}] = chowtest(oil_import, X, breakpoint_candidates(i));
end

% 确定阶段边界
if any(h == 1)
    disp('存在结构性突变');
    breakpoints = breakpoint_candidates(h == 1); % 选择所有显著的断点
else
    disp('不存在结构性突变');
    breakpoints = [5, 10]; % 手动设置阶段边界
end

% 划分数据
oil_import_1 = oil_import(1:breakpoints(1));
oil_import_2 = oil_import(breakpoints(1)+1:breakpoints(2));
oil_import_3 = oil_import(breakpoints(2)+1:end);

% 构建差异化预测模型
% 例如，使用ARIMA模型
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

% 整合能源转型三大关键因素
carbon_price = data(:, 7);
renewable_support = data(:, 8);
geopolitical_factors = data(:, 9);

% 设计动态权重集成预测系统
weights = [0.3, 0.4, 0.3]; % 示例权重
integrated_forecast = weights(1) * forecast1 + weights(2) * forecast2 + weights(3) * forecast3;

% 输出预测结果
disp('预测结果：');
disp(integrated_forecast);