# 数学建模与统计建模作品集

> 四次国家级数学建模 / 统计建模竞赛的作品、核心求解源码（MATLAB + Python）与结果可视化归档：全国大学生数学建模竞赛 ×2（省二）、全国大学生统计建模大赛 ×2（省一）。
> 方法覆盖 **MILP 混合整数规划、MDP 马尔可夫决策、GA+PSO 混合优化、分布鲁棒优化（DRO）、AHP-熵权法、BP/LSTM、Kaplan-Meier 生存分析、XGBoost（回归 + SMOTE 异常分类）、VAR / ARIMAX 机制切换、分位数回归概率区间预测**。

[![CI](https://github.com/ffgxfvy/math-modeling-portfolio/actions/workflows/ci.yml/badge.svg)](https://github.com/ffgxfvy/math-modeling-portfolio/actions/workflows/ci.yml)

---

## 四次竞赛总览

| 年份 | 竞赛 | 题目 | 核心方法 | 成绩 | 目录 |
|---|---|---|---|---|---|
| 2024 | 全国大学生数学建模竞赛 | **生产过程中的决策** | 二项抽样 · MILP · MDP · GA+PSO · 分布鲁棒优化(DRO) · 蒙特卡洛 | 新疆赛区二等奖 | [`national-2024-production-decision/`](national-2024-production-decision/README.md) |
| 2024 | 全国大学生统计建模大赛 | **新基建浪潮下中国传统基建的破局分析** | Voronoi 辐射评估 · AHP-熵权法 · BP 神经网络 · LSTM | 新疆赛区一等奖 | [`statistics-2024-infrastructure/`](statistics-2024-infrastructure/README.md) |
| 2025 | 全国大学生数学建模竞赛 | **NIPT 的时点选择与胎儿异常判定** | Spearman · K-means · Kaplan-Meier · XGBoost 回归/SMOTE 分类 | 新疆赛区二等奖 | [`national-2025-nipt/`](national-2025-nipt/README.md) |
| 2025 | 全国大学生统计建模大赛 | **混合能源市场油价预测** | ETOPI 指标（PCA/PCC/MRA）· VAR · ARIMAX 断点 · Transformer-LSTM-XGBoost · 分位数回归 | 新疆赛区一等奖 | [`statistics-2025-oil-price/`](statistics-2025-oil-price/README.md) |

---

## 代表性亮点与建模思路

1. **`national-2025-nipt/` — 数据科学家式的"先失败、再证伪、再升级"**
   - 问题一先测试线性、多项式与双对数回归均出现欠拟合（$R^2 < 0.1$），遂切换 Spearman 非线性筛查 + **XGBoost + 贝叶斯调参**（测试集 $R^2$ 提升至 `0.794`），并用 **SMOTE + XGBoost 分类**检测胎儿异常（`AUC = 0.952`）。
   - 子目录现已同时归档 MATLAB（`q1`/`q2`/`q4`）与 Python（`q3_spearman_analysis.py`, `q3_xgboost_y_prediction.py`, `q4_chromosome_aneuploidy_classification.py`）完整代码及 Kaplan-Meier 生存曲线。

2. **`national-2024-production-decision/` — 运筹优化与随机不确定性结合**
   - 从单次抽样检测、MILP 混合整数规划，推进至 **MDP 贝尔曼拆解期望 + GA/PSO 混合进化**（`moxing3.m`），最终在问题四中引入**分布鲁棒优化（DRO）+ 蒙特卡洛**应对次品率采样不确定性。

3. **`statistics-2025-oil-price/` — 宏观政策量化 + 分阶段时序预测 + 客观边界透明**
   - 将政策强度、碳价与新能源渗透率量化为 `ETOPI` 复合指标；利用 Chow 断点检测（`arimax_regime_ensemble.m`）与三阶段 VAR 对冲结构迁移；分位数回归输出概率预测区间。
   - 对 `model3_transformer_lstm_xgb.m` 明确标注其外部 `.mat` 配置文件依赖，不包装为“无依赖一键复现”。

---

## 目录结构

```text
math-modeling-portfolio/
├── .github/workflows/ci.yml              # 校验 Python 脚本 AST 语法、PNG 可用性与脱敏规则
├── tests/test_repo_integrity.py          # 仓库结构、无 .bmp 遗留、无本机路径泄露测试
├── national-2024-production-decision/    # 2024 国赛 B 题：4 份 MATLAB 求解源码 + 9 张结果图 + README
├── statistics-2024-infrastructure/       # 2024 统计建模：技术路线图 + BP/LSTM 结果图 + README
├── national-2025-nipt/                   # 2025 国赛 C 题：4 MATLAB + 3 Python 源码 + 5 张结果图 + README
└── statistics-2025-oil-price/            # 2025 统计建模：14 MATLAB 脚本 + 3 张 Web PNG 图 + README
```

## 校验命令

```bash
pytest tests -v
```

## 边界说明与个人职责

- **个人职责**：四次竞赛均为 3 人团队参赛，本人主要承担建模思路拆解、数学规划/机器学习/时序脚本实现、消融可视化与论文撰写工作。
- **不公开内容**：完整参赛论文正文（查重与版权考量）、NIPT 原始医疗检测表、RESSET 商业原始数据集及含个人身份信息的报名/查重报告文件。
