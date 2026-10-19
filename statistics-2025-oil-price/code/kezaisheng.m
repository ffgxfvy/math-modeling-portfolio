% 定义国家数据
countries = {'中国', '美国', '欧盟', '印度', '日本', '巴西'};
years = 2019:2024;
investment_data = [
    83.4   84.6   126.5  164.3  185    213;    % 中国
    55.1   49.3   64.2   114    130    147;     % 美国
    54.8   57.2   68.4   92.1   105    116;     % 欧盟
    9.3    6.9    11.4   15.8   18.5   20.6;    % 印度
    16.7   15.2   19     22.4   24     26;      % 日本
    6.8    7.1    10.2   12.5   14     16.1     % 巴西
];

% 预处理参数
n_countries = length(countries);
excel_file = 'renewable_investment_results.xlsx';

% 删除已存在的文件
if exist(excel_file, 'file')
    delete(excel_file)
end

% 主处理循环
for i = 1:n_countries
    % 获取国家数据
    country = strrep(countries{i}, '/', '_');
    annual_values = investment_data(i, :);
    
    % 生成时间轴
    start_year = years(1);
    end_year = years(end);
    monthly_time = linspace(start_year, end_year + 11/12, (end_year - start_year + 1)*12);
    annual_time = years;  % 新增年度时间轴
    
    % 三次样条插值
    yy = spline(years, annual_values, monthly_time);
    
    % ADF检验
    [h, p] = adftest(yy);
    
    % 标准化处理
    z = zscore(yy);
    
    % 创建数据表
    date_str = datestr(datenum(floor(monthly_time), round(rem(monthly_time,1)*12)+1, 1), 'yyyy-mm');
    data_table = table(cellstr(date_str), yy', z', ...
        'VariableNames', {'Date','Interpolated','ZScore'});
    
    % 写入Excel
    writetable(data_table, excel_file, 'Sheet', country, 'WriteMode','overwritesheet');
    
    % 存储汇总结果
    results(i).country = country;
    results(i).adf_h = h;
    results(i).adf_p = p;
end

% 创建ADF汇总表
adf_summary = table(...
    {results.country}', [results.adf_h]', [results.adf_p]',...
    'VariableNames', {'Country','ADF_Stationary','ADF_pValue'});

% 写入ADF汇总
writetable(adf_summary, excel_file, 'Sheet', 'ADF_Summary', 'WriteMode','overwritesheet');

% 创建数据说明
description = {
    '数据结构说明', '';
    '国家工作表', '包含三列数据：';
    'Date', '年月（格式：YYYY-MM）';
    'Interpolated', '三次样条插值结果（单位：十亿美元）';
    'ZScore', '标准化后的数据';
    'ADF_Summary工作表', '包含两列检验结果：';
    'ADF_Stationary', '1表示平稳，0表示非平稳';
    'ADF_pValue', '显著性p值';
    '数据说明', '原始数据来源：用户提供的2019-2024年度投资额';
    '插值方法', '三次样条插值生成月度数据';
};

writecell(description, excel_file, 'Sheet', '说明', 'Range','A1');

fprintf('处理完成，结果已保存至：%s\n', excel_file);

% 修正后的可视化代码（中国示例）
figure;
% 绘制原始年度数据点（红色圆圈）
plot(annual_time, investment_data(1,:), 'ro', 'MarkerSize', 8, 'LineWidth', 1.5); 
hold on;
% 绘制插值月度曲线（蓝色实线）
plot(monthly_time, yy, 'b-', 'LineWidth', 1.2);
hold off;

title('中国 - 年度数据与插值曲线对比');
xlabel('年份'); 
ylabel('投资额（十亿）');
legend('原始数据','插值曲线', 'Location', 'northwest');
grid on;

% 设置x轴刻度
xticks(2019:1:2024);
xlim([2018.5 2024.5]);