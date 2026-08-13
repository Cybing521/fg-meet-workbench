# 数据来源与口径

本文件保存审计信息，不进入面向老师的报告正文。

## 位移反推

- 修正前后 MATLAB：`data/matlab_inverse_pyro_fix_10x10.csv`
- 修正后 MATLAB--COMSOL：`data/latest_cross_solver_comparison.csv`
- 相对差分母：MATLAB 结果绝对值
- 三个目标位移是同一线性系统的比例缩放，不视为三个独立统计样本
- MATLAB 为 LRT5 壳，COMSOL 为三维二次实体；报告使用“非同构相对差”

## 曲壳表11

- 当前 24 行表：`data/table11_current_layer_local_pyro_v3.csv`
- 当前结果与旧表逐案比较：`data/curvature_current_vs_legacy.csv`
- 四半径几何图：`figures/four_radius_geometry.pdf`
- 网格变化分母：$30\times30$ 中心位移绝对值
- 48 次 MATLAB 求解对应 4 个半径、2 种分布、3 类载荷和 2 级网格

## 代表性曲壳 COMSOL

- MATLAB--COMSOL 模型形式比较：`data/curved_comsol_vs_matlab_model_form.csv`
- 当前只覆盖 $R=0.4$~m、U 分布、15~kPa 压力
- COMSOL 网格数据来自现有代表工况汇总：$10\times10$、$15\times15$、$20\times20$
- 未覆盖 X 分布、电致载荷、磁致载荷、$30\times30$ 网格和其余半径

## 原始正式位置

- `outputs/fgmee_final_delivery_20260720/results/inverse/latest_cross_solver_comparison.csv`
- `outputs/paper-20260715-fgmee/experiments/inverse_sensing/matlab_inverse_pyro_fix_10x10.csv`
- `outputs/fgmee_minimal_issue_report_20260721/table11_current_layer_local_pyro_v3.csv`
- `outputs/fgmee_minimal_issue_report_20260721/curvature_current_vs_legacy.csv`
- `outputs/fgmee_final_delivery_20260720/results/curvature/curved_comsol_vs_matlab_model_form.csv`

