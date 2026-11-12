% 参数设置
mu = 0.05; % 次品率的均值
sigma = 0.02; % 次品率的标准差
c_s = 10; % 抽样单件成本
c_p = 20; % 零件成本
N = 100; % 抽样数量

% 蒙特卡洛模拟
num_simulations = 10000; % 模拟次数
p_values = mu + sigma * randn(num_simulations, 1); % 生成 p 值
cost_values = c_s * N + c_p * N * (1 - p_values); % 计算成本

% 选择最小成本对应的 p 值
[~, min_cost_index] = min(cost_values);
changed_p = p_values(min_cost_index);

% 输出结果
disp(['改变后的次品率：', num2str(changed_p)]);
