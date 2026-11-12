% 定义优化变量
x1 = optimvar('x1', 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
x2 = optimvar('x2', 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
y = optimvar('y', 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
z = optimvar('z', 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
x3 = optimvar('x3', 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
x4 = optimvar('x4', 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
% 定义成本和次品率参数
cp1 = 4; % 零配件1的成本
cp2 = 18; % 零配件2的成本
cr1 = 2; % 检测零配件1的成本
cr2 = 3; % 检测零配件2的成本
cd = 5; % 拆解成本
ci = 6; % 调换成本
cz = 6; % 组装成本
cra =3; % 检测成品的费用（示例值）
p1 = 0.1; % 零配件1的次品率
p2 = 0.1; % 零配件2的次品率
pf = 0.1; % 成品的次品率
% 定义目标函数
costFunction = cp1 + cp2 + cz + cr1*x1 + cr2*x2 + cra*y + ...
(pf+(1-x1)*p1+(1-x2)*p2)*(1-y)*(ci+cz+cp1+cp2)+z*(pf+(1-x1)*p1+(1-x2)*p2)*...
(cd+x3*cr1+x4*cr2-p1*cp1/(p1+p2+pf)*x3-p2*cp2/(p1+p2+pf)*x4-cp1*x1-cp2*x2)+ ...
cp1*(1-x1)*p1 + cp2*(1-x2)*p2;% 定义约束条件
constraints1 = cd*z <= cd*(1 - y); % 拆解成本的约束
constraints2 = ci*(1 - y) == 0; % 调换成本的约束
% 创建优化问题
prob = optimproblem('Objective', costFunction);
% 添加约束到优化问题中
prob.Constraints.cons1 = constraints1;
prob.Constraints.cons2 = constraints2;
% 解决优化问题
[solution, fval] = solve(prob);
% 显示结果
disp(solution);
disp(fval);
