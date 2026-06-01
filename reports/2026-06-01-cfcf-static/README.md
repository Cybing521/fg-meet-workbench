# CFCF 静力边界扩展（2026-06-01）

本报告整理 `run_batch_static_cfcf.m` 的 30x30 静力扫描结果。参数空间为 U/X 两种 FG 分布、Vf0=0.1/0.3/0.5/0.7/0.9、elastic/electro/magneto 三载荷，共 30 行，全部为 ok。

## 关键结论

- CFCF 边界显著抑制中心挠度；elastic 工况中最强抑制为 X/Vf0=0.1，CFCF/CFFF 挠度比 0.055。
- CFCF 下最大的 elastic 中心挠度为 U/Vf0=0.9，|w_center|=0.1764 mm。
- magneto 工况中最高磁电效率为 U/Vf0=0.1，ME efficiency=1.7178。

## 文件

- `data/results_static_cfcf.csv`: 原始 CFCF 结果。
- `data/results_static_cfcf_with_cfff_ratios.csv`: 合并 CFFF 基线后的边界比值。
- `data/cfcf_static_summary_by_group.csv`: 按 FG/载荷聚合。
- `figures/`: 覆盖度、中心挠度、层温差、CFCF/CFFF 比值和磁电效率图。
