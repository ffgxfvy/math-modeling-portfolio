import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.stats import spearmanr
import os

def spearman_correlation_analysis(file_path):
    """
    对指定变量进行Spearman相关性分析并可视化结果
    
    参数:
    file_path: 包含数据的CSV文件路径
    """
    # 设置中文字体，确保中文正常显示
    plt.rcParams["font.family"] = ["SimHei", "WenQuanYi Micro Hei", "Heiti TC"]
    plt.rcParams["axes.unicode_minus"] = False  # 解决负号显示问题
    
    # 读取数据
    try:
        df = pd.read_csv(file_path)
        print("数据读取成功！")
    except Exception as e:
        print(f"数据读取失败: {e}")
        return
    
    # 定义需要分析的变量列表
    variables = [
        '孕周数', '年龄', '孕妇BMI', 'Y染色体的Z值', 
        '身高', '体重', 'GC含量', '被过滤掉读段数的比例', 
        '重复读段的比例', 'X染色体浓度'
    ]
    
    # 检查数据中是否包含所有需要的变量
    missing_vars = [var for var in variables if var not in df.columns]
    if missing_vars:
        print(f"数据中缺少以下变量: {', '.join(missing_vars)}")
        return
    
    # 提取需要分析的变量
    data = df[variables].copy()
    
    # 检查并处理缺失值
    print(f"原始数据形状: {data.shape}")
    print("各变量缺失值统计:")
    print(data.isnull().sum())
    
    # 处理缺失值（删除包含缺失值的行）
    data = data.dropna()
    print(f"处理缺失值后的数据形状: {data.shape}")
    
    # 计算Spearman相关系数和p值
    corr_matrix = pd.DataFrame(index=variables, columns=variables, dtype=np.float64)
    p_matrix = pd.DataFrame(index=variables, columns=variables, dtype=np.float64)
    
    for i, var1 in enumerate(variables):
        for j, var2 in enumerate(variables):
            corr, p_value = spearmanr(data[var1], data[var2])
            corr_matrix.loc[var1, var2] = round(corr, 4)
            p_matrix.loc[var1, var2] = round(p_value, 4)
    
    # 打印相关系数矩阵
    print("\nSpearman相关系数矩阵:")
    print(corr_matrix)
    
    # 打印p值矩阵
    print("\np值矩阵:")
    print(p_matrix)
    
    # 创建结果保存目录
    if not os.path.exists('results'):
        os.makedirs('results')
    
    # 可视化热图 - 相关系数
    plt.figure(figsize=(14, 12))
    mask = np.triu(np.ones_like(corr_matrix, dtype=bool))
    
    sns.heatmap(corr_matrix, mask=mask, annot=True, fmt=".2f", cmap='coolwarm',
                square=True, linewidths=.5, vmin=-1, vmax=1,
                cbar_kws={"shrink": .8})
    
    plt.title('变量间的Spearman相关性热图', fontsize=16)
    plt.tight_layout()
    plt.savefig('results/spearman_correlation_heatmap.png', dpi=300)
    plt.close()
    
    # 可视化热图 - p值（显示显著性）
    plt.figure(figsize=(14, 12))
    # 将p值转换为显著性标记
    sig_matrix = p_matrix.applymap(lambda x: '***' if x < 0.001 else '**' if x < 0.01 else '*' if x < 0.05 else '')
    
    sns.heatmap(corr_matrix, mask=mask, annot=sig_matrix, fmt='', cmap='coolwarm',
                square=True, linewidths=.5, vmin=-1, vmax=1,
                cbar_kws={"shrink": .8})
    
    plt.title('变量间的Spearman相关性显著性热图', fontsize=16)
    plt.tight_layout()
    plt.savefig('results/spearman_significance_heatmap.png', dpi=300)
    plt.close()
    
    print("\n相关性热图已保存至 'results' 文件夹")
    
    # 保存结果为CSV文件
    corr_matrix.to_csv('results/spearman_correlation_matrix.csv')
    p_matrix.to_csv('results/spearman_p_value_matrix.csv')
    print("相关系数矩阵和p值矩阵已保存至 'results' 文件夹")
    
    return corr_matrix, p_matrix

if __name__ == "__main__":
    # 用户需要替换为自己的数据文件路径
    data_file_path = "your_data.csv"  # 请替换为实际数据文件路径
    spearman_correlation_analysis(data_file_path)
