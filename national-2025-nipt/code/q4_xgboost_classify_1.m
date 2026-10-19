% 清除工作空间和命令窗口
clear; clc;

% 从Excel文件导入数据
% 假设Excel文件名为 'nipt_data.xlsx'，数据在第一个工作表的A列
filename = 'C:\Users\32073\Desktop\国赛2\问题四\问题四.xlsx';
sheet = 1;

% 使用readtable读取数据（更可靠的方法）

    % 方法1：使用readtable
    dataTable = readtable(filename, 'Sheet', sheet);
    % 假设数据在第一列
    data = dataTable{:, 20};
    
    % 或者如果知道列名，可以直接指定
    % data = dataTable.XChromosomeConcentration; % 假设列名为XChromosomeConcentration
    

% 确保数据是数值类型
data = double(data);

% 移除可能存在的NaN值
data = data(~isnan(data));

% 检查数据是否有效
if isempty(data)
    error('没有有效数据可供分析。');
end

% 使用箱线图原理检测异常值
Q1 = prctile(data, 25); % 第一四分位数
Q3 = prctile(data, 75); % 第三四分位数
IQR = Q3 - Q1; % 四分位距

% 计算异常值边界（通常使用1.5倍IQR作为标准）
lowerBound = Q1 - 1.5 * IQR;
upperBound = Q3 + 1.5 * IQR;

% 识别异常值
outliers = data(data < lowerBound | data > upperBound);
normalData = data(data >= lowerBound & data <= upperBound);

% 计算正常值的取值范围
normalRange = [min(normalData), max(normalData)];

% 显示结果
fprintf('数据统计摘要:\n');
fprintf('样本总数: %d\n', length(data));
fprintf('异常值数量: %d\n', length(outliers));
fprintf('正常值数量: %d\n', length(normalData));
fprintf('\n正常值取值范围: [%.4f, %.4f]\n', normalRange(1), normalRange(2));
fprintf('第一四分位数 (Q1): %.4f\n', Q1);
fprintf('第三四分位数 (Q3): %.4f\n', Q3);
fprintf('四分位距 (IQR): %.4f\n', IQR);
fprintf('异常值下界: %.4f\n', lowerBound);
fprintf('异常值上界: %.4f\n', upperBound);

% 绘制箱线图可视化结果
figure;
subplot(2, 1, 1);
boxplot(data);
title('原始数据箱线图');
ylabel('X染色体浓度');

subplot(2, 1, 2);
boxplot(normalData);
title('去除异常值后箱线图');
ylabel('X染色体浓度');

% 绘制数据分布图
figure;
hold on;
histogram(data, 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'Normalization', 'probability');
histogram(normalData, 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'Normalization', 'probability');
xline(lowerBound, '--r', 'Lower Bound', 'LineWidth', 1.5);
xline(upperBound, '--r', 'Upper Bound', 'LineWidth', 1.5);
legend('所有数据', '正常值', '异常值边界');
title('X染色体浓度分布');
xlabel('浓度值');
ylabel('概率');
hold off;

% 显示异常值信息
if ~isempty(outliers)
    fprintf('\n异常值列表:\n');
    disp(outliers');
end

% 保存正常值数据到新文件（可选）
% writetable(table(normalData), 'normal_values.xlsx');