countries = {'中国', '美国', '欧盟', '日本', '英国', '印度', '加拿大', '巴西'};
% 紧迫程度评分 [2005年, 2023年]
urgency_scores = [
    8, 5;
    7, 6;
    9, 10;
    6, 7;
    8, 9;
    5, 3;
    7, 6;
    4, 2;
];
% 法力约束力评分 [2005年, 2023年]
constraint_scores = [
    5, 3;
    6, 4;
    10, 8;
    7, 5;
    9, 7;
    3, 2;
    6, 3;
    2, 1;
];

% 时间参数
start_year = 2005;
end_year = 2023;
annual_years = start_year:end_year;
monthly_time = linspace(start_year, end_year + 11/12, (end_year - start_year + 1)*12);

% 预处理
n_countries = length(countries);
results = struct();

for i = 1:n_countries
    % 紧迫程度插值
    urgency = urgency_scores(i, :);
    annual_urgency = spline([start_year, end_year], urgency, annual_years);
    monthly_urgency = spline(annual_years, annual_urgency, monthly_time);
    
    % 法力约束力插值
    constraint = constraint_scores(i, :);
    annual_constraint = spline([start_year, end_year], constraint, annual_years);
    monthly_constraint = spline(annual_years, annual_constraint, monthly_time);
    
    % ADF检验
    [h_urg, p_urg] = adftest(monthly_urgency);
    [h_con, p_con] = adftest(monthly_constraint);
    
    % 标准化
    z_urgency = zscore(monthly_urgency);
    z_constraint = zscore(monthly_constraint);
    
    % 存储结果
    results(i).country = countries{i};
    results(i).urgency = z_urgency;
    results(i).constraint = z_constraint;
    results(i).adf_urgency = [h_urg, p_urg];
    results(i).adf_constraint = [h_con, p_con];
end

% 显示ADF检验结果
for i = 1:n_countries
    fprintf('国家: %s\n', results(i).country);
    fprintf('紧迫程度ADF检验: 平稳性=%d, p值=%.4f\n', results(i).adf_urgency(1), results(i).adf_urgency(2));
    fprintf('法力约束力ADF检验: 平稳性=%d, p值=%.4f\n\n', results(i).adf_constraint(1), results(i).adf_constraint(2));
end

% 可视化示例（中国）
figure;
subplot(2,1,1);
plot(monthly_time, results(1).urgency);
title('中国标准化紧迫程度');
subplot(2,1,2);
plot(monthly_time, results(1).constraint);
title('中国标准化法力约束力');