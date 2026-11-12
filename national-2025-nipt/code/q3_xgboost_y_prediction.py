import pandas as pd
import numpy as np
import xgboost as xgb
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score, mean_absolute_error
import matplotlib.pyplot as plt
import seaborn as sns

# 设置中文显示
plt.rcParams["font.family"] = ["SimHei", "WenQuanYi Micro Hei", "Heiti TC"]
plt.rcParams["axes.unicode_minus"] = False  # 解决负号显示问题

def load_or_create_data(file_path=None):
    """加载数据或创建示例数据"""
    if file_path:
        # 如果提供了文件路径，则尝试加载数据
        try:
            df = pd.read_csv(file_path)
            print(f"成功加载数据，共 {df.shape[0]} 行，{df.shape[1]} 列")
            return df
        except Exception as e:
            print(f"加载数据失败: {e}")
            print("将使用示例数据继续")
    
    # 创建示例数据（实际使用时应替换为真实数据）
    np.random.seed(42)
    n_samples = 500
    
    # 自变量
    gestational_age = np.random.randint(12, 40, n_samples)  # 孕周数（12-40周）
    bmi = np.clip(np.random.normal(24, 4, n_samples), 18, 40)  # 孕妇BMI（18-40）
    age = np.random.randint(18, 45, n_samples)  # 年龄（18-45岁）
    raw_reads = np.random.randint(50000, 1500000, n_samples)  # 原始读段数
    unique_alignments = np.random.randint(30000, 1200000, n_samples)  # 唯一比对的独段数
    
    # 因变量：Y染色体浓度（基于自变量生成，加入相关性和噪声）
    y_chromosome_concentration = (
        0.8 * gestational_age + 
        0.5 * bmi + 
        0.2 * age + 
        0.000015 * raw_reads + 
        0.00002 * unique_alignments + 
        np.random.normal(0, 3, n_samples)  # 加入随机噪声
    )
    # 确保浓度不为负
    y_chromosome_concentration = np.clip(y_chromosome_concentration, 0, None)
    
    # 创建DataFrame
    df = pd.DataFrame({
        '孕周数': gestational_age,
        '孕妇BMI': bmi,
        '年龄': age,
        '原始读段数': raw_reads,
        '唯一比对的独段数': unique_alignments,
        'Y染色体浓度': y_chromosome_concentration
    })
    
    print(f"创建了示例数据，共 {df.shape[0]} 行，{df.shape[1]} 列")
    return df

def analyze_data(df):
    """数据基本分析"""
    print("\n数据基本统计信息：")
    print(df.describe())
    
    # 查看变量间相关性
    print("\n变量间相关性：")
    corr = df.corr()
    print(corr)
    
    # 绘制相关性热力图
    plt.figure(figsize=(10, 8))
    sns.heatmap(corr, annot=True, cmap='coolwarm', fmt='.2f')
    plt.title('变量间相关性热力图')
    plt.tight_layout()
    plt.show()

def train_and_evaluate_model(df):
    """训练并评估XGBoost回归模型"""
    # 分离自变量和因变量
    X = df[['孕周数', '孕妇BMI', '年龄', '原始读段数', '唯一比对的独段数']]
    y = df['Y染色体浓度']
    
    # 划分训练集和测试集（80%训练，20%测试）
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )
    
    print(f"\n训练集大小: {X_train.shape[0]} 样本")
    print(f"测试集大小: {X_test.shape[0]} 样本")
    
    # 创建XGBoost回归模型
    model = xgb.XGBRegressor(
        objective='reg:squarederror',  # 平方误差回归
        n_estimators=100,              # 树的数量
        max_depth=3,                   # 树的最大深度
        learning_rate=0.1,             # 学习率
        subsample=0.8,                 # 每棵树的样本采样比例
        colsample_bytree=0.8,          # 每棵树的特征采样比例
        random_state=42                # 随机种子，保证结果可复现
    )
    
    # 训练模型
    print("\n开始训练模型...")
    model.fit(
        X_train, y_train,
        eval_set=[(X_test, y_test)],
        early_stopping_rounds=10,      # 早停机制
        verbose=False                  # 不打印训练过程
    )
    print("模型训练完成")
    
    # 预测
    y_pred = model.predict(X_test)
    
    # 评估模型性能
    mse = mean_squared_error(y_test, y_pred)
    rmse = np.sqrt(mse)
    mae = mean_absolute_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)
    
    print("\n模型评估指标：")
    print(f"均方误差 (MSE): {mse:.4f}")
    print(f"均方根误差 (RMSE): {rmse:.4f}")
    print(f"平均绝对误差 (MAE): {mae:.4f}")
    print(f"决定系数 (R²): {r2:.4f}")
    
    # 输出特征重要性
    print("\n特征重要性：")
    feature_importance = pd.DataFrame({
        '特征': X.columns,
        '重要性': model.feature_importances_
    }).sort_values('重要性', ascending=False)
    print(feature_importance)
    
    # 可视化特征重要性
    plt.figure(figsize=(10, 6))
    sns.barplot(x='重要性', y='特征', data=feature_importance)
    plt.title('特征重要性')
    plt.tight_layout()
    plt.show()
    
    # 绘制预测值与实际值对比图
    plt.figure(figsize=(10, 6))
    plt.scatter(y_test, y_pred, alpha=0.6, label='预测值')
    plt.plot([y.min(), y.max()], [y.min(), y.max()], 'r--', label='理想预测线')
    plt.xlabel('实际Y染色体浓度')
    plt.ylabel('预测Y染色体浓度')
    plt.title('实际值 vs 预测值')
    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.show()
    
    # 绘制残差图
    residuals = y_test - y_pred
    plt.figure(figsize=(10, 6))
    plt.scatter(y_pred, residuals, alpha=0.6)
    plt.axhline(y=0, color='r', linestyle='--')
    plt.xlabel('预测Y染色体浓度')
    plt.ylabel('残差 (实际值 - 预测值)')
    plt.title('残差图')
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.show()
    
    # 绘制残差分布直方图
    plt.figure(figsize=(10, 6))
    sns.histplot(residuals, kde=True)
    plt.axvline(x=0, color='r', linestyle='--')
    plt.xlabel('残差')
    plt.ylabel('频率')
    plt.title('残差分布')
    plt.grid(True, axis='y', linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.show()
    
    return model

def main():
    print("===== Y染色体浓度预测模型 =====")
    
    # 可以替换为实际数据文件路径，如 "data.csv"
    data_file = None  # 这里使用示例数据
    
    # 加载或创建数据
    df = load_or_create_data(data_file)
    
    # 数据基本分析
    analyze_data(df)
    
    # 训练并评估模型
    model = train_and_evaluate_model(df)
    
    print("\n模型训练和评估完成")

if __name__ == "__main__":
    main()
