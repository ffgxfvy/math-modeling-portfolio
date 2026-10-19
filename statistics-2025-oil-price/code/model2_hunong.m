% 清除工作区和关闭所有图形
clear;
close all;
clc;

% 设置参数
n = 100; % 数据点数量
time = linspace(0, 10, n)'; % 时间轴

% 创建模拟油价趋势：先缓慢上升，再剧烈波动，最后波动中上升
oil_price = zeros(n, 1);
% 第一阶段：缓慢上升 (0-3)
phase1 = time <= 3;
oil_price(phase1) = 50 + 10 * time(phase1);
% 第二阶段：剧烈波动 (3-7)
phase2 = (time > 3) & (time <= 7);
oil_price(phase2) = 80 + 30 * sin(3 * time(phase2)) + 5 * randn(sum(phase2), 1);
% 第三阶段：波动中上升 (7-10)
phase3 = time > 7;
oil_price(phase3) = 90 + 5 * (time(phase3)-7) + 10 * sin(2 * time(phase3)) + 3 * randn(sum(phase3), 1);  % 修复了此行的括号错误

% 创建ETOPI指数 (模拟数据)
etopi = 50 + 20 * sin(0.5 * time) + 5 * randn(n, 1);

% 创建阶段分类 (1, 2, 3)
phase = ones(n, 1);
phase(phase2) = 2;
phase(phase3) = 3;

% 创建三维图形
figure('Position', [100, 100, 900, 700]);
hold on;
grid on;

% 为每个阶段使用不同颜色绘制
colors = [0 0.5 1; 1 0.5 0; 0.5 0 0.5]; % 蓝, 橙, 紫
markers = {'o', 's', '^'}; % 不同阶段的标记形状

for p = 1:3
    idx = (phase == p);
    scatter3(time(idx), etopi(idx), oil_price(idx), 60, ...
            'Marker', markers{p}, ...
            'MarkerFaceColor', colors(p,:), ...
            'MarkerEdgeColor', 'k', ...
            'DisplayName', ['阶段 ' num2str(p)]);
end

% 添加连接线以显示趋势
plot3(time, etopi, oil_price, 'k-', 'LineWidth', 0.5, 'HandleVisibility', 'off');

% 设置图形属性
xlabel('时间 (年)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('ETOPI 指数', 'FontSize', 12, 'FontWeight', 'bold');
zlabel('油价 (美元/桶)', 'FontSize', 12, 'FontWeight', 'bold');
title('阶段和ETOPI指数对油价预测的影响', 'FontSize', 14, 'FontWeight', 'bold');

% 添加图例和颜色条
legend('Location', 'northeast', 'FontSize', 10);
view(-45, 30); % 设置视角

% 添加网格和美化
set(gca, 'FontSize', 11);
box on;
grid minor;
colormap(colors);
caxis([1 3]);

% 添加颜色条表示阶段
c = colorbar('Ticks', [1.33, 2, 2.66], 'TickLabels', {'阶段 1', '阶段 2', '阶段 3'});
c.Label.String = '预测阶段';
c.Label.FontSize = 11;
c.Label.FontWeight = 'bold';

% 旋转3D图形以更好地展示
rotate3d on;
