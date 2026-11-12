% 定义孕期区间和关键点
x_intervals = [26.000, 29.169; 29.169, 35.884; 35.884, 40.138];
interval_lengths = diff(x_intervals, 1, 2);

% 关键点：每个区间中间位置对应的Y值
key_points_x = [mean(x_intervals(1,:)), mean(x_intervals(2,:)), mean(x_intervals(3,:))]; % 区间中点的孕周
key_points_y = [13.71, 15.43, 16.57]; % 对应的Y染色体浓度
threshold = 0.04; % 阈值

% 生成孕期点
x = linspace(26, 40.138, 2000);

% 初始化Y值矩阵
y_zero = zeros(size(x));
y_001 = zeros(size(x));
y_002 = zeros(size(x));

% 为每个区间创建平滑的曲线（每个区间2-3次波动）
for i = 1:3
    idx = x >= x_intervals(i,1) & x <= x_intervals(i,2);
    x_segment = x(idx);
    n_points = sum(idx);
    
    % 每个区间2-3次波动
    num_oscillations = 2 + mod(i, 2); % 2或3次波动
    base_freq = num_oscillations / interval_lengths(i);
    
    % 误差为0的情况 - 低频波动，确保通过关键点
    base_val = key_points_y(i);
    center_x = key_points_x(i);
    
    % 找到最接近中心点的索引
    [~, center_idx] = min(abs(x_segment - center_x));
    target_x = x_segment(center_idx);
    
    % 创建波动函数
    smooth_wave = 1.2 * sin(2*pi*base_freq*(x_segment - x_intervals(i,1))) + ...
                  0.4 * sin(2*pi*base_freq*1.5*(x_segment - x_intervals(i,1)) + pi/3);
    
    % 调整波动使曲线通过关键点
    current_val_at_center = base_val + smooth_wave(center_idx);
    adjustment = key_points_y(i) - current_val_at_center;
    
    % 应用调整，保持波动形状
    y_zero(idx) = base_val + smooth_wave + adjustment;
    
    % 误差为0.01的情况
    if i < 3
        % 前两个区间几乎不变，保持与0误差相同的波动
        small_noise = 0.1 * randn(1, n_points);
        y_001(idx) = y_zero(idx) + small_noise;
    else
        % 最后一个区间有明显上下波动
        high_freq_noise = 0.3 * sin(2*pi*5*(x_segment - x_intervals(i,1))) + ...
                          0.2 * randn(1, n_points);
        y_001(idx) = y_zero(idx) + high_freq_noise;
    end
    
    % 误差为0.02的情况
    if i == 1
        % 第一个区间几乎不变
        minimal_noise = 0.08 * randn(1, n_points);
        y_002(idx) = y_zero(idx) + minimal_noise;
    elseif i == 2
        % 第二个区间有上下波动
        mid_freq_noise = 0.4 * sin(2*pi*3*(x_segment - x_intervals(i,1))) + ...
                         0.25 * randn(1, n_points);
        y_002(idx) = y_zero(idx) + mid_freq_noise;
    else
        % 最后一个区间有显著波动
        severe_noise = 0.6 * sin(2*pi*4*(x_segment - x_intervals(i,1))) + ...
                       0.4 * sin(2*pi*6*(x_segment - x_intervals(i,1)) + pi/3) + ...
                       0.35 * randn(1, n_points);
        y_002(idx) = y_zero(idx) + severe_noise;
    end
end

% 确保所有曲线在阈值0.04之上（90%的数据点）
for i = 1:3
    idx = x >= x_intervals(i,1) & x <= x_intervals(i,2);
    
    % 对每条曲线进行调整，确保90%的点在阈值之上
    y_zero(idx) = ensure_coverage(y_zero(idx), threshold, 0.90);
    y_001(idx) = ensure_coverage(y_001(idx), threshold, 0.90);
    y_002(idx) = ensure_coverage(y_002(idx), threshold, 0.90);
end

% 绘制图形
figure('Position', [100, 100, 1000, 700]);
hold on;

% 绘制三条曲线
p1 = plot(x, y_zero, 'b-', 'LineWidth', 2.5, 'DisplayName', '误差水平 = 0');
p2 = plot(x, y_001, 'r-', 'LineWidth', 2, 'DisplayName', '误差水平 = 0.01');
p3 = plot(x, y_002, 'g-', 'LineWidth', 2, 'DisplayName', '误差水平 = 0.02');

% 标记关键点
for i = 1:3
    plot(key_points_x(i), key_points_y(i), 'ko', 'MarkerSize', 12, ...
        'MarkerFaceColor', 'k', 'DisplayName', sprintf('关键点 %d', i));
    
    % 添加关键点标注
    text(key_points_x(i), key_points_y(i) - 0.8, ...
        sprintf('(%.1f周, %.2f)', key_points_x(i), key_points_y(i)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
        'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 9);
end

% 添加阈值线
yline(threshold, 'k--', 'LineWidth', 2, 'DisplayName', '阈值 (0.04)', 'Alpha', 0.7);

% 添加区间分隔线和标注
for i = 1:size(x_intervals,1)
    xline(x_intervals(i,1), 'k:', 'LineWidth', 1.5, 'Alpha', 0.6);
    xline(x_intervals(i,2), 'k:', 'LineWidth', 1.5, 'Alpha', 0.6);
    
    % 区间标注
    mid_x = mean(x_intervals(i,:));
    text(mid_x, 19, sprintf('[%.3f, %.3f]', x_intervals(i,1), x_intervals(i,2)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'BackgroundColor', 'white', ...
        'EdgeColor', 'black');
end

% 设置图形属性
xlabel('bmi', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('孕周', 'FontSize', 13, 'FontWeight', 'bold');
title('不同误差水平下的Y染色体浓度生存函数曲线', 'FontSize', 15, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 11);
grid on;
set(gca, 'GridAlpha', 0.3, 'FontSize', 11);

% 设置坐标轴范围
xlim([26, 40.138]);
ylim([10, 20]);

% 添加统计信息
stats_text = {
    '关键点对应关系:', ...
    sprintf('区间1: 孕周%.1f → Y=%.2f', key_points_x(1), key_points_y(1)), ...
    sprintf('区间2: 孕周%.1f → Y=%.2f', key_points_x(2), key_points_y(2)), ...
    sprintf('区间3: 孕周%.1f → Y=%.2f', key_points_x(3), key_points_y(3)), ...
    '', ...
    '所有曲线: 90%数据点 > 0.04'
};

annotation('textbox', [0.15, 0.15, 0.3, 0.18], 'String', stats_text, ...
    'FitBoxToText', 'on', 'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 9);

hold off;

% 辅助函数：确保指定比例的点在阈值之上
function adjusted_segment = ensure_coverage(segment, threshold, coverage)
    adjusted_segment = segment;
    below_threshold = segment < threshold;
    n_below = sum(below_threshold);
    total_points = numel(segment);
    
    required_above = round(coverage * total_points);
    current_above = total_points - n_below;
    
    if current_above < required_above
        [~, sort_idx] = sort(segment);
        need_to_adjust = required_above - current_above;
        
        for j = 1:min(need_to_adjust, n_below)
            adjusted_segment(sort_idx(j)) = threshold + 0.005 + 0.01 * rand();
        end
    end
end