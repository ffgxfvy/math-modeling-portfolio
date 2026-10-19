% 油价预测MATLAB示例（最终修正版）
clc;
clear;
close all;

% 1. 生成模拟历史油价数据（2020年1月-2024年4月）
startDate = datetime(2020,1,1);
endDate = datetime(2024,4,1);
dates = startDate:calmonths(1):endDate;
numPeriods = length(dates);

% 基础油价 + 季节性波动 + 随机波动
basePrice = 50 + 10*sin((1:numPeriods)*2*pi/12); 
shock1 = 20*exp(-0.5*((1:numPeriods)-15).^2/100); % 模拟2021年价格冲击
shock2 = 15*exp(-0.5*((1:numPeriods)-40).^2/100); % 模拟2022年价格冲击
noise = randn(1,numPeriods)*5;

oilPrice = basePrice + shock1 + shock2 + noise;
oilPrice(oilPrice<0) = 10; % 确保价格不为负

% 2. 创建时间序列表（修正变量名）
oilData = timetable(dates', oilPrice', 'VariableNames', {'Price'});
oilData.Properties.DimensionNames{1} = 'Date'; % 确保第一列名为Date

% 3. 准备预测模型（ARIMA）
% 使用估计结果中的参数初始化模型
model = arima(2,1,2);
model.Constant = -0.39733;
model.AR = {-0.88599 -0.36711}; % 使用您运行结果中的参数
model.MA = {0.67068 0.47149};
model.Variance = 54.88;

% 4. 进行未来12个月预测
numForecastSteps = 12;
[forecastPrice, YMSE] = forecast(model, numForecastSteps, 'Y0', oilData.Price);

% 计算置信区间
confInterval = 1.96*sqrt(YMSE); % 95%置信区间
lowerBound = forecastPrice - confInterval;
upperBound = forecastPrice + confInterval;

% 5. 创建预测时间轴
forecastDates = dates(end) + calmonths(1:numForecastSteps);

% 6. 可视化结果
figure('Position', [100, 100, 900, 500]);
hold on;

% 绘制历史数据（修正引用方式）
plot(oilData.Date, oilData.Price, 'b-', 'LineWidth', 2, 'DisplayName', '历史油价');

% 绘制预测数据
plot(forecastDates, forecastPrice, 'r--', 'LineWidth', 2, 'DisplayName', '预测油价');

% 绘制置信区间
fill([forecastDates, fliplr(forecastDates)], ...
     [lowerBound', fliplr(upperBound')], ...
     'r', 'FaceAlpha', 0.1, 'EdgeColor', 'none', ...
     'DisplayName', '95%置信区间');

% 添加标记线
plot([dates(end), forecastDates(1)], ...
     [oilData.Price(end), forecastPrice(1)], 'r--', 'LineWidth', 2, ...
     'HandleVisibility', 'off');

% 图表美化
title('国际油价历史数据与未来12个月预测', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('日期', 'FontSize', 12);
ylabel('油价 (美元/桶)', 'FontSize', 12);
grid on;
legend('Location', 'best');
datetick('x', 'yyyy-mm', 'KeepLimits');
xticks(dates(1:6:end)); % 每6个月显示一个刻度
xtickangle(45);

% 添加注释
annotation('textbox', [0.15, 0.7, 0.2, 0.1], 'String', ...
    sprintf('当前油价: %.2f$\n预测末值: %.2f$', oilData.Price(end), forecastPrice(end)), ...
    'FitBoxToText', 'on', 'BackgroundColor', 'white');

hold off;