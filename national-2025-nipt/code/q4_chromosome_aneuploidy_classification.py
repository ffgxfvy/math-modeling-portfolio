import pandas as pd
import numpy as np
import xgboost as xgb
from sklearn.model_selection import train_test_split
from sklearn.metrics import (accuracy_score, precision_score, recall_score, 
                             f1_score, roc_auc_score, confusion_matrix, 
                             classification_report, roc_curve)
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt
import seaborn as sns
from imblearn.over_sampling import SMOTE  # 处理类别不平衡

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
            # 检查必要的列是否存在
            required_columns = ['染色体的非整倍体', '预测结果Y', '预测测试结果概率_0.0', 
                               '预测测试结果概率_1.0', '年龄', '检测抽血次数', '孕妇BMI',
                               '原始读段数', '在参考基因组上比对的比例', '重复读段的比例',
                               '唯一比对的读段数', 'X染色体浓度', 'GC含量', 
                               '被过滤掉读段数的比例', '13号染色体的Z值']
            
            missing_cols = [col for col in required_columns if col not in df.columns]
            if missing_cols:
                print(f"警告：数据中缺少必要的列：{missing_cols}")
                return None
            
            return df
        except Exception as e:
            print(f"加载数据失败: {e}")
            print("将使用示例数据继续")
    
    # 创建示例数据（实际使用时应替换为真实数据）
    np.random.seed(42)
    n_samples = 1000
    
    # 生成特征变量
    age = np.random.randint(18, 45, n_samples)  # 年龄（18-45岁）
    blood_draws = np.random.randint(1, 4, n_samples)  # 检测抽血次数（1-3次）
    bmi = np.clip(np.random.normal(24, 4, n_samples), 18, 40)  # 孕妇BMI（18-40）
    raw_reads = np.random.randint(50000, 1500000, n_samples)  # 原始读段数
    alignment_ratio = np.clip(np.random.normal(0.85, 0.08, n_samples), 0.5, 1.0)  # 比对比例
    duplicate_ratio = np.clip(np.random.normal(0.15, 0.05, n_samples), 0.01, 0.5)  # 重复读段比例
    unique_reads = np.random.randint(30000, 1200000, n_samples)  # 唯一比对的读段数
    x_concentration = np.clip(np.random.normal(50, 15, n_samples), 10, 100)  # X染色体浓度
    gc_content = np.clip(np.random.normal(0.4, 0.05, n_samples), 0.3, 0.6)  # GC含量
    filtered_ratio = np.clip(np.random.normal(0.1, 0.05, n_samples), 0.01, 0.3)  # 被过滤读段比例
    chr13_zscore = np.random.normal(0, 1, n_samples)  # 13号染色体的Z值
    
    # 生成目标变量：染色体的非整倍体（0:正常，1:异常）- 模拟不平衡数据
    # 基于一些特征生成概率，使结果更合理
    prob = 1 / (1 + np.exp(-(
        0.03 * age + 
        0.1 * blood_draws + 
        0.02 * bmi +
        0.0000001 * raw_reads +
        -1 * alignment_ratio +
        2 * duplicate_ratio +
        -0.0000001 * unique_reads +
        0.01 * x_concentration +
        -1 * gc_content +
        2 * filtered_ratio +
        0.5 * abs(chr13_zscore) - 3.5  # Z值绝对值越大，异常可能性越高
    )))
    
    aneuploidy = np.where(np.random.random(n_samples) < prob, 1, 0)
    
    # 生成预测结果Y和概率（模拟之前的预测结果）
    pred_y = np.where(np.random.random(n_samples) < prob * 0.9 + 0.05, 1, 0)
    pred_prob_0 = 1 - prob * 0.9 - 0.05 + np.random.normal(0, 0.03, n_samples)
    pred_prob_0 = np.clip(pred_prob_0, 0.01, 0.99)
    pred_prob_1 = 1 - pred_prob_0
    
    # 创建DataFrame
    df = pd.DataFrame({
        '染色体的非整倍体': aneuploidy,
        '预测结果Y': pred_y,
        '预测测试结果概率_0.0': pred_prob_0,
        '预测测试结果概率_1.0': pred_prob_1,
        '年龄': age,
        '检测抽血次数': blood_draws,
        '孕妇BMI': bmi,
        '原始读段数': raw_reads,
        '在参考基因组上比对的比例': alignment_ratio,
        '重复读段的比例': duplicate_ratio,
        '唯一比对的读段数': unique_reads,
        'X染色体浓度': x_concentration,
        'GC含量': gc_content,
        '被过滤掉读段数的比例': filtered_ratio,
        '13号染色体的Z值': chr13_zscore
    })
    
    print(f"创建了示例数据，共 {df.shape[0]} 行，{df.shape[1]} 列")
    print(f"类别分布：正常(0) {sum(aneuploidy == 0)} 例，异常(1) {sum(aneuploidy == 1)} 例")
    return df

def analyze_data(df):
    """数据基本分析"""
    print("\n数据基本统计信息：")
    print(df.describe())
    
    # 查看目标变量分布
    plt.figure(figsize=(8, 5))
    sns.countplot(x='染色体的非整倍体', data=df)
    plt.title('染色体非整倍体类别分布')
    plt.xlabel('类别 (0: 正常, 1: 异常)')
    plt.ylabel('样本数量')
    for i, count in enumerate(df['染色体的非整倍体'].value_counts().sort_index()):
        plt.text(i, count + 5, str(count), ha='center')
    plt.tight_layout()
    plt.show()
    
    # 查看数值型变量的分布
    numeric_features = ['年龄', '孕妇BMI', '原始读段数', '在参考基因组上比对的比例',
                       '重复读段的比例', '唯一比对的读段数', 'X染色体浓度', 
                       'GC含量', '被过滤掉读段数的比例', '13号染色体的Z值']
    
    plt.figure(figsize=(18, 12))
    for i, feature in enumerate(numeric_features, 1):
        plt.subplot(3, 4, i)
        sns.histplot(data=df, x=feature, hue='染色体的非整倍体', kde=True, element='step')
        plt.title(f'{feature} 分布')
    plt.tight_layout()
    plt.show()
    
    # 查看变量间相关性
    plt.figure(figsize=(12, 10))
    corr = df.corr()
    sns.heatmap(corr, annot=True, cmap='coolwarm', fmt='.2f', linewidths=0.5)
    plt.title('变量间相关性热力图')
    plt.tight_layout()
    plt.show()
    
    # 查看特征与目标变量的相关性
    target_corr = corr['染色体的非整倍体'].sort_values(ascending=False)
    print("\n特征与目标变量的相关性：")
    print(target_corr)

def train_and_evaluate_model(df):
    """训练并评估XGBoost分类模型"""
    # 定义特征和目标变量
    features = ['预测结果Y', '预测测试结果概率_0.0', '预测测试结果概率_1.0', 
               '年龄', '检测抽血次数', '孕妇BMI', '原始读段数', 
               '在参考基因组上比对的比例', '重复读段的比例', '唯一比对的读段数', 
               'X染色体浓度', 'GC含量', '被过滤掉读段数的比例', '13号染色体的Z值']
    target = '染色体的非整倍体'
    
    X = df[features]
    y = df[target]
    
    # 划分训练集和测试集（80%训练，20%测试）
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y  # stratify确保分层抽样，保持类别比例
    )
    
    print(f"\n训练集大小: {X_train.shape[0]} 样本")
    print(f"测试集大小: {X_test.shape[0]} 样本")
    print(f"训练集类别分布: 正常(0) {sum(y_train == 0)} 例, 异常(1) {sum(y_train == 1)} 例")
    print(f"测试集类别分布: 正常(0) {sum(y_test == 0)} 例, 异常(1) {sum(y_test == 1)} 例")
    
    # 处理类别不平衡
    print("\n应用SMOTE处理类别不平衡...")
    smote = SMOTE(random_state=42)
    X_train_resampled, y_train_resampled = smote.fit_resample(X_train, y_train)
    print(f"重采样后训练集类别分布: 正常(0) {sum(y_train_resampled == 0)} 例, 异常(1) {sum(y_train_resampled == 1)} 例")
    
    # 特征标准化（对树模型不是必须的，但可以让某些可视化更直观）
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train_resampled)
    X_test_scaled = scaler.transform(X_test)
    
    # 创建XGBoost分类模型
    model = xgb.XGBClassifier(
        objective='binary:logistic',  # 二分类逻辑回归
        n_estimators=100,             # 树的数量
        max_depth=3,                  # 树的最大深度
        learning_rate=0.1,            # 学习率
        subsample=0.8,                # 每棵树的样本采样比例
        colsample_bytree=0.8,         # 每棵树的特征采样比例
        scale_pos_weight=sum(y_train==0)/sum(y_train==1),  # 处理不平衡的权重
        random_state=42,              # 随机种子，保证结果可复现
        use_label_encoder=False,
        eval_metric='logloss'
    )
    
    # 训练模型
    print("\n开始训练模型...")
    model.fit(
        X_train_resampled, y_train_resampled,
        eval_set=[(X_test, y_test)],
        early_stopping_rounds=10,     # 早停机制
        verbose=False                 # 不打印训练过程
    )
    print("模型训练完成")
    
    # 预测
    y_pred = model.predict(X_test)
    y_pred_proba = model.predict_proba(X_test)[:, 1]  # 预测为1的概率
    
    # 评估模型性能
    print("\n模型评估指标：")
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred)
    recall = recall_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred)
    roc_auc = roc_auc_score(y_test, y_pred_proba)
    
    print(f"准确率 (Accuracy): {accuracy:.4f}")
    print(f"精确率 (Precision): {precision:.4f}")
    print(f"召回率 (Recall): {recall:.4f}")
    print(f"F1分数 (F1 Score): {f1:.4f}")
    print(f"ROC曲线下面积 (AUC): {roc_auc:.4f}")
    
    # 混淆矩阵
    print("\n混淆矩阵：")
    cm = confusion_matrix(y_test, y_pred)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', cbar=False,
                xticklabels=['正常(0)', '异常(1)'],
                yticklabels=['正常(0)', '异常(1)'])
    plt.xlabel('预测类别')
    plt.ylabel('实际类别')
    plt.title('混淆矩阵')
    plt.tight_layout()
    plt.show()
    
    # 详细分类报告
    print("\n分类报告：")
    print(classification_report(y_test, y_pred, target_names=['正常(0)', '异常(1)']))
    
    # 特征重要性
    print("\n特征重要性：")
    feature_importance = pd.DataFrame({
        '特征': features,
        '重要性': model.feature_importances_
    }).sort_values('重要性', ascending=False)
    print(feature_importance)
    
    # 可视化特征重要性
    plt.figure(figsize=(12, 8))
    sns.barplot(x='重要性', y='特征', data=feature_importance)
    plt.title('特征重要性')
    plt.tight_layout()
    plt.show()
    
    # ROC曲线
    fpr, tpr, thresholds = roc_curve(y_test, y_pred_proba)
    plt.figure(figsize=(8, 6))
    plt.plot(fpr, tpr, label=f'ROC曲线 (AUC = {roc_auc:.4f})')
    plt.plot([0, 1], [0, 1], 'k--', label='随机猜测')
    plt.xlabel('假阳性率 (FPR)')
    plt.ylabel('真阳性率 (TPR)')
    plt.title('ROC曲线')
    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.show()
    
    # 预测概率分布
    plt.figure(figsize=(10, 6))
    sns.histplot(data=pd.DataFrame({'预测概率': y_pred_proba, '实际类别': y_test}),
                 x='预测概率', hue='实际类别', multiple='stack', bins=20)
    plt.axvline(x=0.5, color='r', linestyle='--', label='分类阈值 (0.5)')
    plt.xlabel('预测为异常(1)的概率')
    plt.ylabel('样本数量')
    plt.title('预测概率分布')
    plt.legend(title='实际类别', labels=['正常(0)', '异常(1)', '分类阈值'])
    plt.grid(True, axis='y', linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.show()
    
    return model

def main():
    print("===== 染色体非整倍体分类模型 =====")
    
    # 可以替换为实际数据文件路径，如 "chromosome_data.csv"
    data_file = None  # 这里使用示例数据
    
    # 加载或创建数据
    df = load_or_create_data(data_file)
    if df is None:
        print("数据加载失败，程序退出")
        return
    
    # 数据基本分析
    analyze_data(df)
    
    # 训练并评估模型
    model = train_and_evaluate_model(df)
    
    print("\n模型训练和评估完成")

if __name__ == "__main__":
    main()
    