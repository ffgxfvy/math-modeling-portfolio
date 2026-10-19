data = readtable('C:\Users\32073\Desktop\国赛2\问题二拟合\022（29.91-32.895）.xlsx'); 
filePath = 'C:\Users\32073\Desktop\国赛2\问题二拟合\022（29.91-32.895）.xlsx'; 

 originalTable = readtable(filePath);

    disp('表格列名：');
    disp(originalTable.Properties.VariableNames);
    columnName = 'x_______';
results = struct();

fprintf('=== 原始数据分析 ===\n');
[shortest_time_original, survFunc_original, weeks_original] = ...
    analyzeSurvival(gestational_weeks, y_chromosome_concentration, confidence_level, 1);

fprintf('\n=== 蒙特卡洛模拟分析 ===\n');
for i = 1:length(error_levels)
    error_std = error_levels(i);
    fprintf('\n分析误差水平: %.4f\n', error_std);
    
    shortest_times = zeros(n_simulations, 1);
    
    for sim = 1:n_simulations
  
        measurement_error = error_std * randn(size(y_chromosome_concentration));
        y_concentration_noisy = y_chromosome_concentration + measurement_error;
        
  
        [shortest_time, ~, ~] = analyzeSurvival(gestational_weeks, y_concentration_noisy, confidence_level, 0);
        shortest_times(sim) = shortest_time;

        if mod(sim, 100) == 0
            fprintf('完成 %d/%d 次模拟\n', sim, n_simulations);
        end
    end
    

    results(i).error_level = error_std;
    results(i).shortest_times = shortest_times;
    results(i).mean_time = mean(shortest_times);
    results(i).std_time = std(shortest_times);
    results(i).median_time = median(shortest_times);
    results(i).ci_95 = prctile(shortest_times, [2.5, 97.5]);
    
    fprintf('平均最短时间: %.3f ± %.3f 孕周\n', results(i).mean_time, results(i).std_time);
    fprintf('90%%置信区间: [%.3f, %.3f] 孕周\n', results(i).ci_95(1), results(i).ci_95(2));
end

plotMonteCarloResults(results, shortest_time_original, error_levels);


generateReport(results, shortest_time_original);


function [shortest_time, survFunc, weeks] = analyzeSurvival(weeks_data, concentration_data, confidence_level, verbose)
    gestational_weeks = [0; weeks_data(:)];
    y_concentration = [0.04; concentration_data(:)];
    
    event = y_concentration > 0.04;
    event(1) = 0; 

    [weeks_sorted, sort_idx] = sort(gestational_weeks);
    concentration_sorted = y_concentration(sort_idx);
    event_sorted = event(sort_idx);
    
    try
        [survFunc, weeks, lowerCI, upperCI] = ecdf(weeks_sorted,...
                                                  'censoring', ~event_sorted,...
                                                  'function', 'survivor',...
                                                  'alpha', 0.05);
    catch
        survFunc = ones(size(weeks_sorted));
        weeks = weeks_sorted;
    end
    
    threshold_index = find(survFunc < (1 - confidence_level), 1, 'first');
    
    if ~isempty(threshold_index) && ~isnan(weeks(threshold_index))
        shortest_time = weeks(threshold_index);
        if verbose
            fprintf('最短时间: %.3f 孕周\n', shortest_time);
        end
    else
        shortest_time = NaN;
        if verbose
            fprintf('未找到满足条件的时间点\n');
        end
    end
end

function plotMonteCarloResults(results, original_time, error_levels)
    figure('Position', [100, 100, 1200, 800]);
    
  
    
    % 子图2：统计量比较
    subplot(2, 2, 2);
    means = [results.mean_time];
    stds = [results.std_time];
    errorbar(1:length(error_levels), means, stds, 'o-',...
            'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
    hold on;
    plot(1:length(error_levels), repmat(original_time, 1, length(error_levels)), 'r--',...
         'LineWidth', 2, 'DisplayName', '原始估计');
    set(gca, 'XTick', 1:length(error_levels),...
             'XTickLabel', arrayfun(@(x) sprintf('%.3f', x), error_levels, 'UniformOutput', false));
    xlabel('检测误差水平');
    ylabel('平均最短时间（孕周）');
    title('检测误差对估计结果的影响');
    legend('带误差估计', '原始估计');
    grid on;
    
  
    for k = 1:length(h)
        h(k).FaceAlpha = 0.7;
    end
    set(gca, 'XTick', 1:length(error_levels),...
             'XTickLabel', arrayfun(@(x) sprintf('%.3f', x), error_levels, 'UniformOutput', false));
    xlabel('检测误差水平');
    ylabel('绝对偏差（孕周）');
    title('估计偏差 vs 误差水平');
    grid on;
    
    sgtitle('检测误差对生存曲线分析结果的蒙特卡洛模拟分析');
end

function generateReport(results, original_time)
    fprintf('\n=== 蒙特卡洛模拟分析报告 ===\n');
    fprintf('原始估计的最短时间: %.3f 孕周\n', original_time);
    fprintf('\n误差水平影响分析:\n');
    fprintf('误差水平\t平均时间\t标准差\t偏差\t\t95%% CI宽度\n');
    fprintf('--------\t--------\t------\t------\t---------\n');
    
    for i = 1:length(results)
        bias = results(i).mean_time - original_time;
        ci_width = diff(results(i).ci_95);
        fprintf('%.4f\t\t%.3f\t\t%.3f\t%.3f\t%.3f\n',...
                results(i).error_level, results(i).mean_time,...
                results(i).std_time, bias, ci_width);
    end
    
    fprintf('\n误差敏感性分析:\n');
    errors = [results.error_level];
    means = [results.mean_time];
    
    if length(errors) > 1
        sensitivity = diff(means) ./ diff(errors);
        fprintf('误差敏感性系数: %.3f (孕周/误差单位)\n', mean(sensitivity));
    end

    acceptable_bias = 0.1; 
    acceptable_ci_width = 0.5; 
    
    recommended_levels = find([results.std_time] <= acceptable_bias &...
                            arrayfun(@(x) diff(x.ci_95), results) <= acceptable_ci_width);
    
    if ~isempty(recommended_levels)
        fprintf('推荐的最大可接受误差水平: %.4f\n', results(recommended_levels(1)).error_level);
    else
        fprintf('所有测试的误差水平都超出可接受范围\n');
        fprintf('建议将检测误差控制在 %.4f 以下\n', min([results.error_level]));
    end
    
    figure;
    plot([results.error_level], abs([results.mean_time] - original_time), 'o-',...
        'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
    xlabel('检测误差水平');
    ylabel('估计偏差（孕周）');
    title('检测误差与估计偏差的关系');
    grid on;
    
    p = polyfit([results.error_level], abs([results.mean_time] - original_time), 1);
    x_fit = linspace(min([results.error_level]), max([results.error_level]), 100);
    y_fit = polyval(p, x_fit);
    hold on;
    plot(x_fit, y_fit, 'r--', 'LineWidth', 2);
    legend('观测数据', sprintf('拟合线: y = %.3fx + %.3f', p(1), p(2)));
end