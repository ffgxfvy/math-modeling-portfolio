% 定义国家数据
countries = {'中国', '美国', '欧盟27国', '印度', '日本', '巴西'};
years = 2020:2024;
raw_data = {
    -0.087   -0.081    -0.08     -0.067    -0.079    % 中国
    -0.073   -0.074    -0.072     -0.055    -0.069    % 美国
    -0.086   -0.081    -0.076     -0.059    -0.076    % 欧盟27国
    -0.087   -0.082    -0.075     -0.082    -0.081    % 印度
    '-7.5%*' '-7.8%*'  '-6.5%*'  '-5.0%*'  -0.067     % 日本
    '-6.2%*' '-6.5%*'  '-6.0%*'  '-5.3%*'  -0.06      % 巴西
};

% 数据清洗转换（修正版本）
clean_data = zeros(size(raw_data));
for i = 1:size(raw_data,1)
    for j = 1:size(raw_data,2)
        cell_content = raw_data{i,j};
        
        % 统一转换为字符串处理
        if isnumeric(cell_content)
            str_value = num2str(cell_content);
        else
            str_value = char(cell_content);
        end
        
        % 清洗处理
        if contains(str_value, {'%','*'})
            % 移除特殊字符并转换百分比
            cleaned_str = strrep(str_value, '%', '');
            cleaned_str = strrep(cleaned_str, '*', '');
            clean_data(i,j) = str2double(cleaned_str)/100;
        else
            clean_data(i,j) = str2double(str_value);
        end
    end
end

% 预处理参数
n_countries = length(countries);
excel_file = 'cost_reduction_results.xlsx';

% 删除已存在的文件
if exist(excel_file, 'file')
    delete(excel_file)
end

% 主处理循环
for i = 1:n_countries
    % 获取国家数据
    country = strrep(countries{i}, ' ', '_'); % 处理特殊字符
    annual_values = clean_data(i, :);
    
    % 生成时间轴
    start_year = years(1);
    end_year = years(end);
    monthly_time = linspace(start_year, end_year + 11/12, (end_year - start_year + 1)*12);
    annual_time = years;
    
    % 三次样条插值
    yy = spline(annual_time, annual_values, monthly_time);
    
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
    'Interpolated', '三次样条插值结果（成本下降率）';
    'ZScore', '标准化后的数据';
    'ADF_Summary工作表', '包含两列检验结果：';
    'ADF_Stationary', '1表示平稳，0表示非平稳';
    'ADF_pValue', '显著性p值';
    '数据说明', '原始数据处理：';
    '   ', '1. 百分比转换（如-7.5%→-0.075）';
    '   ', '2. 去除特殊字符(*)';
    '插值方法', '三次样条插值生成月度数据';
};

writecell(description, excel_file, 'Sheet', '说明', 'Range','A1');

fprintf('处理完成，结果已保存至：%s\n', excel_file);

% 可视化示例（中国）
figure;
subplot(2,1,1);
plot(annual_time, clean_data(1,:), 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);
hold on;
plot(monthly_time, yy, 'b-', 'LineWidth', 1.2);
hold off;
title('中国成本下降率插值结果');
xlabel('年份'); ylabel('下降率');
legend('原始数据','插值曲线', 'Location','southeast');
grid on;

subplot(2,1,2);
plot(monthly_time, z, 'g-', 'LineWidth', 1.2);
title('标准化后的序列');
xlabel('年份'); ylabel('Z-Score');
grid on;