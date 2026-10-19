
data = readtable('C:\Users\32073\Desktop\国赛2\问题二拟合\022（29.91-32.895）.xlsx'); 
filePath = 'C:\Users\32073\Desktop\国赛2\问题二拟合\022（29.91-32.895）.xlsx'; 


 originalTable = readtable(filePath);
   
    disp('表格列名：');
    disp(originalTable.Properties.VariableNames);
    
    columnName = 'x_______'; 
    

gestational_weeks = data.Var1;
y_chromosome_concentration = data.Var3; 

gestational_weeks = [0; gestational_weeks]; 
y_chromosome_concentration = [0.04; y_chromosome_concentration]; 

event = y_chromosome_concentration > 0.04;
event(1) = 0; 


[survFunc, weeks, lowerCI, upperCI] = ecdf(gestational_weeks, 'censoring', ~event,...
                                          'function', 'survivor',...
                                          'alpha', 0.1);

confidence_level = 0.90;
threshold_index = find(survFunc < (1 - confidence_level), 1, 'first');

if ~isempty(threshold_index)
    shortest_time = weeks(threshold_index);
    fprintf('在90%%置信条件下，Y染色体浓度超过0.04的最短时间为: %.2f 孕周\n', shortest_time);
    figure;
    stairs(weeks, survFunc, 'b-', 'LineWidth', 2);
    hold on;
    stairs(weeks, lowerCI, 'r--', 'LineWidth', 1.5);
    stairs(weeks, upperCI, 'r--', 'LineWidth', 1.5);

    plot(shortest_time, survFunc(threshold_index), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    line([shortest_time, shortest_time], [0, survFunc(threshold_index)], 'Color', 'k', 'LineStyle', ':');
    line([min(weeks), shortest_time], [survFunc(threshold_index), survFunc(threshold_index)], 'Color', 'k', 'LineStyle', ':');
    
    xlabel('孕周');
    ylabel('生存概率（浓度≤0.04的概率）');
    title('Y染色体浓度超过0.04的生存曲线');
    legend('Kaplan-Meier估计', '90%置信下限', '90%置信上限', '最短时间点', 'Location', 'best');
    grid on;
    
    fprintf('在孕周 %.2f 时，生存概率为 %.4f\n', shortest_time, survFunc(threshold_index));
    fprintf('90%%置信区间: [%.4f, %.4f]\n', lowerCI(threshold_index), upperCI(threshold_index));
else
    fprintf('在90%%置信条件下未找到Y染色体浓度超过0.04的时间点\n');
end

fprintf('\n生存曲线数据:\n');
fprintf('孕周\t生存概率\t90%%CI下限\t90%%CI上限\n');
for i = 1:length(weeks)
    fprintf('%.2f\t%.4f\t%.4f\t%.4f\n', weeks(i), survFunc(i), lowerCI(i), upperCI(i));
end