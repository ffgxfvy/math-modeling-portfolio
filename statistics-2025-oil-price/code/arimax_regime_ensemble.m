%% 主程序部分
% 完整数据输入
data = [
2010 239.3 87 199.49 1 447 0 7 5
2011 253.6 88.5 203.89 1.12 475 0 7 5
2012 271 89.8 204.92 1.12 495 0 7 5
2013 282 91.2 209.03 1.12 518 0 7 5
2014 308 93 210.11 1.4 535 0 7 5
2015 335.5 92.5 199.69 1.52 555 0 9 5
2016 381 92 191.5 1.52 578 0 9 5
2017 420 93.5 191.95 1.52 605 0 9 5
2018 462 94.8 189.11 1.52 635 0 9 5
2019 506 95.2 191.01 1.52 675 20 9 5
2020 542.4 94 194.92 1.52 685 25 9 5
2021 513 96.8 198.98 1.52 690 49 10 5
2022 508.28 99.8 204.66 1.52 670 56 10 5
2023 563.99 101 208.91 1.52 710 70 10 5
2024 570.06 102.5 210 1.52 740 92 10 5
];

% 变量初始化
years = data(:,1);
imports = data(:,2);         % 原油进口量
prod_world = data(:,3);      % 世界产量
prod_domestic = data(:,4);   % 国内产量
fuel_tax = data(:,5);        % 燃油税
demand = data(:,6);          % 总需求
carbon_sink = data(:,7);     % 碳汇
new_energy = data(:,8);      % 新能源评分
geo_political = data(:,9);   % 地缘政治

%% 结构性突变检测
X = [ones(length(years),1), (years-years(1))];
break_points = [6,11]; % 调整后的断点索引

disp('结构性突变检测结果:');
for i = 1:length(break_points)
    [F,p] = chow_test(demand,X,break_points(i));
    fprintf('在%d年检测到断点: F统计量=%.2f(p值=%.4f)\n',...
        years(break_points(i)),F,p);
end

%% 阶段划分调整（两个阶段）
stage{1} = 1:7;    % 2010-2016 (7个观测)
stage{2} = 8:15;   % 2017-2024 (8个观测)

%% 分阶段建模
exog_vars = [fuel_tax, carbon_sink, new_energy]; % 外生变量
models = cell(2,1);
forecasts = cell(2,1);

for s = 1:2
    idx = stage{s};
    y = demand(idx);
    exog = exog_vars(idx,:);
    
    % 自动选择简化模型
    if length(y) >= 7
        % 使用ARIMAX(1,0,1)模型（移除差分项）
        model = arima('ARLags',1,'D',0,'MALags',1);
        model = estimate(model,y,'X',exog);
        [yF,~] = forecast(model,length(y),'Y0',y,'X0',exog,'XF',exog);
    else
        % 使用移动平均作为备用方案
        warning('阶段%d样本不足，使用移动平均预测',s);
        yF = smoothdata(y,'movmean',3);
        model = []; % 空模型占位
    end
    
    models{s} = model;
    forecasts{s} = yF;
end

%% 动态权重集成预测系统
weights = ones(2,1)/2;      % 初始等权重
final_forecast = zeros(size(demand));
window_size = 3;           % 误差计算窗口
lambda = 0.85;             % 遗忘因子

for t = 1:length(years)
    % 确定当前所属阶段
    current_stage = find(cellfun(@(x) ismember(t,x), stage));
    
    % 各模型预测值
    y_hat = zeros(2,1);
    for s = 1:2
        if ~isempty(models{s}) && t <= length(stage{s})
            exog = exog_vars(t,:);
            y_hat(s) = forecast(models{s},1,...
                'Y0',demand(1:t),...
                'X0',exog_vars(1:t,:),...
                'XF',exog);
        else
            y_hat(s) = forecasts{s}(t - stage{s}(1) + 1);
        end
    end
    
    % 动态更新权重
    if t > window_size
        errors = zeros(2,1);
        for s = 1:2
            valid_range = stage{s}(stage{s} <= t-1);
            if length(valid_range) >= window_size
                err = demand(valid_range(end-window_size+1:end) )
                    forecasts{s}(end-window_size+1:end);
                errors(s) = mean(abs(err));
            else
                errors(s) = Inf; % 无足够数据时赋极大值
            end
        end
        weights = exp(-lambda*errors)./sum(exp(-lambda*errors));
    end
    
    % 加权综合预测
    final_forecast(t) = sum(weights.*y_hat);
end

%% 可视化结果
figure('Position',[100 100 800 400])
plot(years,demand,'bo-','LineWidth',1.5,'MarkerSize',8,...
    'MarkerFaceColor','w','DisplayName','实际需求');
hold on;
plot(years,final_forecast,'r^--','LineWidth',1.5,'MarkerSize',8,...
    'MarkerFaceColor','r','DisplayName','集成预测');
xlabel('年份','FontSize',12);
ylabel('原油需求量 (百万吨)','FontSize',12);
title('分阶段动态权重预测结果','FontSize',14);
legend('Location','best');
grid on;
set(gca,'FontName','Microsoft YaHei'); % 中文显示优化

%% 性能评估
mse = mean((demand - final_forecast).^2);
mae = mean(abs(demand - final_forecast));
fprintf('\n模型评估结果:\n');
fprintf('均方误差(MSE): %.2f\n',mse);
fprintf('平均绝对误差(MAE): %.2f\n',mae);

%% 函数定义必须放在文件末尾
function [F_stat, p_val] = chow_test(y,X,bp)
    % Chow断点检验函数
    n = size(X,1);
    k = size(X,2);
    
    % 全样本模型
    [~,~,~,~,RSS] = regress(y,X);
    
    % 分段模型
    [~,~,~,~,RSS1] = regress(y(1:bp),X(1:bp,:));
    [~,~,~,~,RSS2] = regress(y(bp+1:end),X(bp+1:end,:));
    
    % 计算F统计量
    F_stat = ((RSS - (RSS1+RSS2))/k)/((RSS1+RSS2)/(n-2*k));
    p_val = 1 - fcdf(F_stat,k,n-2*k);
end