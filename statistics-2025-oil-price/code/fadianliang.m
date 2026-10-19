

clc
clear
close all


try
）
    dataFile = 'C:\Users\32073\Desktop\统计建模2\碳价数据预处理\碳价数据.xlsx';
    opts = detectImportOptions(dataFile);
    opts.VariableNamesRange = 'A1';  
    data = readtable(dataFile, opts);
    dateCol = find(contains(data.Properties.VariableNames, {'Date','时间','月份'}, 'IgnoreCase', true));
    priceCol = find(contains(data.Properties.VariableNames, {'Price','价格','碳价'}, 'IgnoreCase', true));    
    dateStrings = data.(dateCol);
    prices = data.(priceCol);
catch
    error('数据读取失败，请检查文件路径和列名');
end


try
    if iscell(dateStrings)
        dateStrings = string(dateStrings);
    end
    
    dates = NaT(size(dateStrings));
    for i = 1:length(dateStrings)
        try
            dates(i) = datetime(dateStrings(i), 'InputFormat', 'MMM-yy', 'Locale', 'en_US');
        catch
            dates(i) = datetime(dateStrings(i), 'InputFormat', 'yyyy.MM');
        end
    end
    

    dates = dates - caldays(day(dates)-1);
    dates.Format = 'MMM-yy'; 
catch ME
    error('日期解析失败: %s', ME.message);
end

tt_original = timetable(dates, prices, 'VariableNames', {'Price'});

start_date = dates(1);
end_date = dates(end);
full_dates = (start_date:calmonths(1):end_date)';

if length(dates) == length(full_dates)
    disp('-- 数据已具完整月度频率，跳过插值 --');
    tt = tt_original;
else
    disp('-- 执行三次样条插值 --');
    
    valid_mask = ~isnan(prices);
    if sum(valid_mask) < 3
        error('有效数据点不足（需≥3），无法插值');
    end
    
    x = datenum(dates(valid_mask));
    y = prices(valid_mask);
    xq = datenum(full_dates);
    
    interp_prices = interp1(x, y, xq, 'spline');
    
    tt = timetable(full_dates, interp_prices, 'VariableNames', {'Price'});
end

max_lags = min(12, floor(length(tt.Price)/4));  

[~, ~, ~, ~, reg] = arrayfun(@(lag) adftest(tt.Price, 'model','TS','lags',lag), 0:max_lags);

if isfield(reg(1), 'TestStatistic')
    stat_field = 'TestStatistic';
else
    stat_field = 'TestStat'; 

aic_values = [reg.AIC];
[~, optimal_idx] = min(aic_values);
optimal_lag = optimal_idx - 1;

fprintf('\n=== ADF检验结果 ===\n');
fprintf('最优滞后阶数: %d (AIC=%.2f)\n', optimal_lag, aic_values(optimal_idx));
fprintf('检验统计量(%s): %.4f\n', stat_field, reg(optimal_idx).(stat_field));
fprintf('p值: %.4f\n', reg(optimal_idx).PValue);

alpha = 0.05;
if reg(optimal_idx).PValue < alpha
    fprintf('=> 序列平稳 (p < %.2f)\n', alpha);
else
    fprintf('=> 序列非平稳 (p >= %.2f)\n', alpha);
end


tt.ZScore = (tt.Price - mean(tt.Price)) / std(tt.Price);

median_price = median(tt.Price);
mad_price = mad(tt.Price, 1); 
tt.RobustZ = (tt.Price - median_price) / mad_price;

figure('Position', [100 100 900 600])

subplot(2,2,[1 2])
plot(tt.Time, tt.Price, 'b-o', 'MarkerSize',4, 'LineWidth',1.5)
title('碳价时序趋势', 'FontSize',12, 'FontWeight','bold')
ylabel('价格 (元/吨)')
grid on
xlim([min(tt.Time) max(tt.Time)])

subplot(2,2,3)
plot(0:max_lags, aic_values, 'k-s', 'MarkerFaceColor','r')
title('AIC准则选择滞后阶数', 'FontSize',10)
xlabel('滞后阶数')
ylabel('AIC值')
grid on

subplot(2,2,4)
plot(tt.Time, tt.ZScore, 'b-', 'LineWidth',1.5)
hold on
plot(tt.Time, tt.RobustZ, 'r--', 'LineWidth',1.5)
yline(0, 'k--')
title('标准化方法对比', 'FontSize',10)
legend('Z-score', '鲁棒标准化', 'Location','best')
ylim([-3 3])
grid on

tt.Properties.VariableUnits = {'元/吨', '标准差单位', 'MAD单位'};
tt.Properties.VariableDescriptions = {
    '原始碳价（含插值）', 
    'Z-score标准化结果', 
    '基于中位数-MAD的鲁棒标准化'
};

writetimetable(tt, 'C:\Users\32073\Desktop\统计建模2\碳价数据预处理\processed_carbon_price.xlsx');
disp('== 处理完成，结果已保存为 processed_carbon_price.csv ==');