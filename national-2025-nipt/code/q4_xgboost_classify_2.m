% 读取Excel文件，保留原始列标题
data = readtable('C:\Users\32073\Desktop\国赛2\问题四\13.xlsx', 'VariableNamingRule', 'preserve');

% 显示列名以确认
disp('列名:');
disp(data.Properties.VariableNames);

% 提取染色体的非整倍数列（最后一列）
non_aneuploidy = data{:, end};

% 获取所有列名
all_names = data.Properties.VariableNames;

% 初始化存储结果的数组
variables = {};
rhos = [];
p_values = [];
n_samples = [];

% 对除了最后一列的每个指标计算斯皮尔曼等级相关系数
for i = 1:(width(data)-1)
    try
        % 尝试提取当前列的数据
        current_data = data{:, i};
        
        % 如果数据是单元格数组，尝试转换为数值
        if iscell(current_data)
            % 尝试将单元格内容转换为数值
            numeric_data = zeros(size(current_data));
            for j = 1:length(current_data)
                if ischar(current_data{j}) || isstring(current_data{j})
                    % 如果是文本，尝试转换为数值
                    numeric_data(j) = str2double(current_data{j});
                else
                    numeric_data(j) = current_data{j};
                end
            end
            current_data = numeric_data;
        end
        
        % 移除NaN值
        valid_idx = ~isnan(current_data) & ~isnan(non_aneuploidy);
        if sum(valid_idx) < 3  % 至少需要3个数据点
            fprintf('跳过 %s: 有效数据点不足\n', all_names{i});
            continue;
        end
        
        % 计算斯皮尔曼相关系数
        [rho, p] = corr(current_data(valid_idx), non_aneuploidy(valid_idx), 'Type', 'Spearman');
        
        % 存储结果到数组
        variables{end+1} = all_names{i};
        rhos(end+1) = rho;
        p_values(end+1) = p;
        n_samples(end+1) = sum(valid_idx);
        
        fprintf('指标: %-20s 相关系数: %8.4f p值: %8.4e 样本数: %d\n', ...
                all_names{i}, rho, p, sum(valid_idx));
                
    catch ME
        fprintf('处理 %s 时出错: %s\n', all_names{i}, ME.message);
        variables{end+1} = all_names{i};
        rhos(end+1) = NaN;
        p_values(end+1) = NaN;
        n_samples(end+1) = 0;
    end
end

% 创建结果表格
result_table = table(variables', rhos', p_values', n_samples', ...
    'VariableNames', {'Variable', 'Spearman_Rho', 'P_Value', 'Sample_Size'});

% 按p值排序
[~, sort_idx] = sort(p_values);
result_table = result_table(sort_idx, :);

% 显示所有结果
fprintf('\n=== 所有指标的相关性分析结果 ===\n');
disp(result_table);

% 显示显著的结果（p < 0.05）
significant_mask = result_table.P_Value < 0.05 & ~isnan(result_table.P_Value);
significant_results = result_table(significant_mask, :);

if height(significant_results) > 0
    fprintf('\n=== 显著相关的结果 (p < 0.05) ===\n');
    disp(significant_results);
else
    fprintf('\n没有发现显著相关的结果 (p < 0.05)\n');
end

% 绘制所有相关系数的条形图
valid_mask = ~isnan(result_table.Spearman_Rho);
if sum(valid_mask) > 0
    figure('Position', [100, 100, 1200, 600]);
    
    % 提取有效数据
    valid_vars = result_table.Variable(valid_mask);
    valid_rhos = result_table.Spearman_Rho(valid_mask);
    valid_p = result_table.P_Value(valid_mask);
    
    % 创建条形图
    bar_handles = bar(valid_rhos);
    
    % 设置x轴标签
    set(gca, 'XTick', 1:length(valid_vars), ...
             'XTickLabel', valid_vars, ...
             'XTickLabelRotation', 45, ...
             'FontSize', 8);
    
    ylabel('斯皮尔曼相关系数');
    title('染色体的非整倍数与各指标的斯皮尔曼相关系数');
    grid on;
    
    % 添加数值标签
    for i = 1:length(valid_rhos)
        if valid_p(i) < 0.05
            color = 'r'; % 显著结果用红色
            marker = '*';
        else
            color = 'k'; % 不显著结果用黑色
            marker = '';
        end
        
        text(i, valid_rhos(i) + 0.02 * sign(valid_rhos(i)), ...
             sprintf('%.3f%s', valid_rhos(i), marker), ...
             'HorizontalAlignment', 'center', ...
             'FontSize', 8, ...
             'Color', color);
    end
    
    % 添加图例
    legend('相关系数', 'Location', 'best');
    
    % 添加显著性标记
    hold on;
    sig_idx = find(valid_p < 0.05);
    if ~isempty(sig_idx)
        scatter(sig_idx, valid_rhos(sig_idx) + 0.05, 50, 'r*');
        legend([bar_handles, scatter(sig_idx(1), valid_rhos(sig_idx(1)) + 0.05)], ...
               {'相关系数', '显著 (p < 0.05)'}, 'Location', 'best');
    end
    hold off;
end

% 保存结果到Excel文件
writetable(result_table, '相关性分析结果.xlsx');
fprintf('\n结果已保存到 "相关性分析结果.xlsx"\n');

% 显示相关性最强的几个指标
fprintf('\n=== 相关性最强的5个指标 ===\n');
top_results = result_table(1:min(5, height(result_table)), :);
disp(top_results);