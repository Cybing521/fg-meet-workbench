# 第一点验证：机械力加载产生位移是否算对
核对时间：2026-06-11

## 结论
机械力加载产生位移这条主链路**可以作为本周汇报的第一点验证内容**：当前 MATLAB 取位移方式已经修正为先还原完整 `TQd` 再取中心节点，COMSOL 载荷口径与 MATLAB Case A 一致，非孔隙代表工况的 COMSOL 15 点误差均低于 5%。

但如果按导师希望的 1%--3% 更严格口径，目前还**不能说完全达标**：U/V/X/CFCF 的 15 点最大误差为 3.831%--4.927%，仍需要补钱沈云/赵亚飞或已发表文献的同工况外部对照。

## 关键证据

### 1. MATLAB 程序取值问题已修正
- `matlab/run_meet_static.m` 现在执行 `TQd = restore_mechanical_dof(FinitElemInfo.Node, Qd)`，随后用 `TQd(5*(centerIdx-1)+3)` 取中心横向位移。
- 旧的 `results_static.pre-wcenter-refresh-20260522-193011.csv` 中，U/Vf0=0.6/elastic 的中心位移为 -0.360862 mm；修正后的 `output/results_static.csv` 为 -2.127520 mm。这个差异说明之前确实存在 reduced `Qd` 后处理错位，且当前已修正。

### 2. 力加载口径一致
- MATLAB Case A：`LoadScale = -15000`，通过表面载荷向量 `FusT` 施加均布压力。
- COMSOL：`BoundaryLoad` 使用 `ForceArea`，`FperArea = [0, 0, -15000 N/m^2]`，顶面加载。
- 载荷方向、量级和顶面选择在 `tools/comsol/RunElasticCfffValidation.java` 与 `comsol/docs/equivalent-loads.md` 中一致。

### 3. U/Vf0=0.6/CFFF 已重算验证
本次用 MATLAB 重新读取 `.mat` 与 COMSOL 原始点表生成 `recomputed_validation_points_U_Vf06_elastic_layered_csv_sweep7_mesh4.csv`。重算摘要：
- 中心点 p8：MATLAB -2.127520 mm，COMSOL -2.207739 mm，误差 3.771%。
- 15 点最大误差：4.927%（p15，坐标 (0.25, 0.25)），平均误差 3.513%。
- 与原始仓库表的数值最大差异：matlab_w_mm=3.997e-15, comsol_w_mm=4.441e-15, diff_w_mm=4.996e-16, rel_err_w_pct=3.997e-15。

## 非孔隙代表工况汇总
| 工况 | 中心误差 | 15点最大误差 | 平均误差 | 最大误差点 | <5% 判断 | <3% 判断 |
|---|---:|---:|---:|---|---|---|
| U/Vf0=0.6/CFFF | 3.771% | 4.927% | 3.513% | p15 (0.25, 0.25) | 通过 | 未通过 |
| V/Vf0=0.6/CFFF | 2.959% | 4.190% | 2.958% | p15 (0.25, 0.25) | 通过 | 未通过 |
| X/Vf0=0.6/CFFF | 2.839% | 4.060% | 2.790% | p5 (0.25, 0.05) | 通过 | 未通过 |
| X/Vf0=0.1/CFCF | 3.831% | 3.831% | 1.684% | p8 (0.15, 0.15) | 通过 | 未通过 |

## 汇报建议
可以讲：
- “力加载产生位移这一项，当前程序已经修正了中心位移读取方式，并用 COMSOL 独立模型做了 15 点对照；非孔隙代表工况全部在 5% 内。”
- “这说明机械力到位移的主链路是可用的，可作为后续电/磁驱动和回代验证的第一步。”

需要谨慎讲：
- 不能说“已经达到师姐 1%--3% 水平”，因为 15 点最大误差仍为 3.831%--4.927%。
- 不能说“已经和钱沈云/赵亚飞结果对上”，因为当前仓库没有找到同工况外部基准值。

下一步：拿到师姐或文献的同几何、同材料、同边界、同载荷位移结果后，填入 `external_validation_template.csv` 的 force_to_displacement 行，形成 MATLAB / COMSOL / 外部基准三方对比。

## 输出文件
- `force_displacement_validation_summary.csv`：第一点非孔隙代表工况汇总。
- `U_Vf06_mesh_experiment_summary.csv`：U/Vf0=0.6 网格和建模实验过程。
- `recomputed_validation_points_U_Vf06_elastic_layered_csv_sweep7_mesh4.csv`：本次 MATLAB 重算的 15 点明细。
