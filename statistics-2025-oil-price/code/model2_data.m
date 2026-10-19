% 原始数据
years = [2010:2024]';
oil_import = [239.3; 253.6; 271; 282; 308; 335.5; 381; 420; 462; 506; 542.4; 513; 508.28; 563.99; 570.06];
world_production = [87; 88.5; 89.8; 91.2; 93; 92.5; 92; 93.5; 94.8; 95.2; 94; 96.8; 99.8; 101; 102.5];
domestic_production = [199.49; 203.89; 204.92; 209.03; 210.11; 199.69; 191.5; 191.95; 189.11; 191.01; 194.92; 198.98; 204.66; 208.91; 210];
fuel_tax = [1; 1.12; 1.12; 1.12; 1.4; 1.52; 1.52; 1.52; 1.52; 1.52; 1.52; 1.52; 1.52; 1.52; 1.52];
total_demand = [447; 475; 495; 518; 535; 555; 578; 605; 635; 675; 685; 690; 670; 710; 740];
new_energy_support = [7; 7; 7; 7; 7; 9; 9; 9; 9; 9; 9; 10; 10; 10; 10];

% 创建数据矩阵
data = [oil_import, world_production, domestic_production, fuel_tax, total_demand, new_energy_support];

% 标准化处理 (Z-score标准化)
standardized_data = zscore(data);

% 显示标准化后的数据
disp('标准化后的数据:');
disp(array2table(standardized_data, 'VariableNames', {'OilImport', 'WorldProduction', 'DomesticProduction', 'FuelTax', 'TotalDemand', 'NewEnergySupport'}, 'RowNames', string(years)));

% 可视化结果
figure;

% 创建子图1: 原始数据
subplot(2,1,1);
plot(years, data, 'LineWidth', 1.5);
title('原始数据');
xlabel('年份');
ylabel('数值');
legend({'原油进口量', '世界原油产量', '国内原油产量', '燃油税税率', '原油总需求量', '新能源扶持力度'}, 'Location', 'northwest');
grid on;

% 创建子图2: 标准化后的数据
subplot(2,1,2);
plot(years, standardized_data, 'LineWidth', 1.5);
title('标准化后的数据');
xlabel('年份');
ylabel('标准化值');
legend({'原油进口量', '世界原油产量', '国内原油产量', '燃油税税率', '原油总需求量', '新能源扶持力度'}, 'Location', 'northwest');
grid on;

% 调整图形布局
set(gcf, 'Position', [100, 100, 800, 600]);