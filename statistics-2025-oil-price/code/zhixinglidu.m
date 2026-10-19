countries = {'欧盟', '美国', '中国', '印度', '日本', '英国', '巴西', '俄罗斯'};
start_years = [1990, 2005, 2005, 2005, 2013, 1990, 2005, 1990];
target_years = [2030, 2030, 2030, 2030, 2030, 2035, 2030, 2030];
aer_ter_percent = [58, 33, 78, 62, 26, 63, 24, 113];

% 转换为小数
execution_ratio = aer_ter_percent / 100;

% 预处理
n = length(countries);
results = struct();
excel_file = 'carbon_policy_results.xlsx';

% 删除已存在的文件
if exist(excel_file, 'file')
    delete(excel_file)
end

% 主处理循环
for i = 1:n
    % 获取数据
    country = strrep(countries{i}, '/', '_'); % 处理特殊字符
    sy = start_years(i);
    ty = target_years(i);
    ratio = execution_ratio(i);
    
    % 构造插值点
    x = [sy, 2022, ty];
    y = [0, ratio, 1.0];
    
    % 生成月度时间轴
    monthly_time = sy:1/12:ty + 11/12;
    
    % 三次样条插值
    yy = spline(x, y, monthly_time);
    
    % ADF检验
    [h, p] = adftest(yy);
    
    % 标准化
    z = zscore(yy);
    
    % 存储结果
    results(i).country = country;
    results(i).monthly_time = monthly_time;
    results(i).interpolated = yy;
    results(i).zscore = z;
    results(i).adf_h = h;
    results(i).adf_p = p;
    
    % 创建数据表
    date_str = datestr(datenum(floor(monthly_time), rem(monthly_time,1)*12+1, 1), 'yyyy-mm');
    data_table = table(cellstr(date_str), yy', z', ...
        'VariableNames', {'Date','Interpolated','ZScore'});
    
    % 写入Excel
    writetable(data_table, excel_file, 'Sheet', country, 'WriteMode','overwritesheet');
end

% 创建ADF汇总表
adf_summary = table(...
    {results.country}', [results.adf_h]', [results.adf_p]',...
    'VariableNames', {'Country','ADF_Stationary','ADF_pValue'});

% 写入ADF汇总
writetable(adf_summary, excel_file, 'Sheet', 'ADF_Summary', 'WriteMode','overwritesheet');

% 创建数据说明
description = {
    'Sheet结构说明', '';
    '国家工作表', '包含三列数据：';
    'Date', '年月（格式：YYYY-MM）';
    'Interpolated', '三次样条插值结果（0-1范围）';
    'ZScore', '标准化后的数据';
    'ADF_Summary工作表', '包含两列检验结果：';
    'ADF_Stationary', '1表示平稳，0表示非平稳';
    'ADF_pValue', '显著性p值'
};

writecell(description, excel_file, 'Sheet', '说明', 'Range','A1');

fprintf('结果已保存至：%s\n', excel_file);