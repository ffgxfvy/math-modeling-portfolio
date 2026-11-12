% 创建三维曲面图  
[E, N] = meshgrid(E_values, linspace(0, 2000, 100));  
Z = (Z_alpha_95 * sqrt(p0 * (1 - p0)) ./ E).^2; % 示例函数  

figure;  
surf(E, N, Z);  
xlabel('允许误差 (E)');  
ylabel('样本量 (n)');  
zlabel('计算值');  
title('三维曲面图');  
colorbar;
