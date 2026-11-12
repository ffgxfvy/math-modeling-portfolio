function hybrid_optimization_example()
    % 定义参数
    num_parts = 8;  % 零配件数量
    num_half_products = 3;  % 半成品数量
    population_size = 100;  % 种群大小
    num_generations = 100;  % 迭代次数
    mutation_rate = 0.1;  % 变异率

    % PSO参数
    num_particles = 50;  % 粒子数量
    inertia_weight = 0.7;  % 惯性权重
    cognitive_weight = 1.5;  % 认知学习因子
    social_weight = 1.5;  % 社会学习因子

    % 零配件的参数
    purchase_price = [2, 8, 12, 2, 8, 12, 8, 12];
    detection_cost = [1, 1, 2, 1, 1, 2, 1, 2];
    allpurchase_price = 64;
    % 装配成本
    assembly_cost = 32;  % 总装配成本

    % 拆解回收效益
    recovery_value = [15.1648, 13.8000, 13.8000, 47.6000];  % 不合格半成品1, 半成品2, 半成品3, 成品的回收效益

    % 成品调换成本
    return_cost_per_product = 40;  % 每件成品的调换成本

    % 初始化种群
    population = randi([0, 1], population_size, num_parts + num_half_products + 5); % 增加拆解决策位和调换决策位

    % 初始化PSO
    particles = randi([0, 1], num_particles, num_parts + num_half_products + 5);
    velocities = rand(num_particles, num_parts + num_half_products + 5) - 0.5;
    personal_best_positions = particles;
    personal_best_scores = arrayfun(@(idx) fitness(particles(idx, :), purchase_price, detection_cost, assembly_cost, recovery_value, return_cost_per_product), 1:num_particles);
    [global_best_score, global_best_idx] = min(personal_best_scores);
    global_best_position = personal_best_positions(global_best_idx, :);

    % 初始化适应度记录
    best_fitness_per_generation = zeros(num_generations, 1);

    % 主循环
    for generation = 1:num_generations
        % 计算适应度
        fitness_values = arrayfun(@(idx) fitness(population(idx, :), purchase_price, detection_cost, assembly_cost, recovery_value, return_cost_per_product), 1:population_size);

        % 确保适应度值为非负
        fitness_values = max(fitness_values, 0);  % 将负值替换为0

        % 记录每代的最佳适应度
        best_fitness_per_generation(generation) = min(fitness_values);

        % PSO更新粒子
        for i = 1:num_particles
            % 更新速度和位置
            velocities(i, :) = inertia_weight * velocities(i, :) + ...
                               cognitive_weight * rand() * (personal_best_positions(i, :) - particles(i, :)) + ...
                               social_weight * rand() * (global_best_position - particles(i, :));
            particles(i, :) = particles(i, :) + round(velocities(i, :));
            particles(i, :) = min(max(particles(i, :), 0), 1);  % 保证粒子位置在[0,1]范围内
            
            % 计算适应度并更新个人最优
            current_score = fitness(particles(i, :), purchase_price, detection_cost, assembly_cost, recovery_value, return_cost_per_product);
            if current_score < personal_best_scores(i)
                personal_best_scores(i) = current_score;
                personal_best_positions(i, :) = particles(i, :);
            end
            
            % 更新全局最优
            if current_score < global_best_score
                global_best_score = current_score;
                global_best_position = particles(i, :);
            end
        end

        % 更新GA种群
        selected_indices = selection(fitness_values);
        selected_population = population(selected_indices, :);

        % 交叉和变异
        new_population = [];
        for i = 1:2:population_size
            parent1 = selected_population(i, :);
            parent2 = selected_population(i + 1, :);
            [child1, child2] = crossover(parent1, parent2);
            new_population = [new_population; mutate(child1, mutation_rate); mutate(child2, mutation_rate)];
        end

        population = new_population;
    end

    % 找到最优解
    fitness_values = arrayfun(@(idx) fitness(population(idx, :), purchase_price, detection_cost, assembly_cost, recovery_value, return_cost_per_product), 1:population_size);
    fitness_values = max(fitness_values, 0);  % 确保最优解的适应度值为非负
    [min_cost, best_index] = min(fitness_values);
    best_solution = population(best_index, :);

    fprintf('最佳决策方案: %s\n', mat2str(best_solution));

    % 绘制最佳适应度图表
    figure;
    plot(1:num_generations, best_fitness_per_generation, 'LineWidth', 2);
    xlabel('代数');
    ylabel('最佳适应度');
    title('混合优化算法进化过程');
    grid on;

    % 绘制种群适应度分布图表
    figure;
    histogram(fitness_values, 'Normalization', 'pdf');
    xlabel('适应度值');
    ylabel('概率密度');
    title('最终种群适应度分布');
    grid on;
end

function cost = fitness(individual, purchase_price, detection_cost, assembly_cost, recovery_value, return_cost_per_product)
    detection_decisions = individual(1:8);  % 检测决策
    half_product_decisions = individual(9:11);  % 半成品检测决策
    product_decision = individual(12);  % 成品检测决策
    disassemble_decision_half = individual(13:15);  % 半成品拆解决策
    disassemble_decision_product = individual(16);  % 成品拆解决策

    % 计算检测成本
    total_detection_cost = sum(detection_decisions .* detection_cost);

    % 计算装配成本
    total_assembly_cost = assembly_cost;  % 成品装配成本固定为32

    % 计算调换成本
    return_cost = 0;  % 初始化调换成本

    % 计算成品和半成品的次品率
    half_product_defective_rate = 0.1;  % 半成品的次品率
    product_defective_rate = 0.1;  % 成品的次品率

    % 计算拆解成本和回收效益
    total_disassemble_cost = 0;
    total_recovery_value = 0;

    % 处理半成品
    for i = 1:length(half_product_decisions)
        if half_product_decisions(i) == 1  % 如果选择检测半成品
            if rand < half_product_defective_rate  % 检测到次品
                total_disassemble_cost = total_disassemble_cost + 6;  % 假设拆解成本为6
                total_recovery_value = total_recovery_value + recovery_value(i);  % 获取回收效益
            end
        end
    end

    % 处理成品
    if product_decision == 1  % 如果选择检测成品
        if rand < product_defective_rate  % 检测到次品
            total_disassemble_cost = total_disassemble_cost + 10;  % 假设拆解成本为10
            total_recovery_value = total_recovery_value + recovery_value(end);  % 获取成品的回收效益
            return_cost = return_cost_per_product;  % 计算调换成本
        else
            return_cost = 0;  % 如果没有检测到次品，不计算调换成本
        end
    end

    % 计算总成本
    cost = total_detection_cost + total_disassemble_cost + total_assembly_cost + return_cost - total_recovery_value;
end

function selected_indices = selection(fitness_values)
    % 选择操作，轮盘赌选择
    fitness_sum = sum(fitness_values);
    if fitness_sum == 0
        selected_indices = randi(length(fitness_values), size(fitness_values));
    else
        probabilities = fitness_values / fitness_sum;
        selected_indices = randsample(length(fitness_values), length(fitness_values), true, probabilities);
    end
end

function [child1, child2] = crossover(parent1, parent2)
    % 单点交叉
    crossover_point = randi(length(parent1) - 1);
    child1 = [parent1(1:crossover_point), parent2(crossover_point + 1:end)];
    child2 = [parent2(1:crossover_point), parent1(crossover_point + 1:end)];
end

function mutated_individual = mutate(individual, mutation_rate)
    % 变异操作
    mutated_individual = individual;
    mutation_mask = rand(size(individual)) < mutation_rate;
    mutated_individual(mutation_mask) = 1 - mutated_individual(mutation_mask);  % 0变1, 1变0
end

