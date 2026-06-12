# 第五点：加力产生位移与师姐结果核对

更新时间：2026-06-12

## 结论

现在可以严谨地说：**力产生位移这一点，已经和钱沈云论文机械载荷自由端中点对上，也已经和钱沈云代码同工况 15 点/全自由度结果对上**。但还不能说我们自己的 15 点 COMSOL 3D solid 表全部进入 3%。

可以确认的是：

- 钱沈云论文 Table 2/Table 3 已经给出了机械载荷外部基准：15000 Pa 均布载荷下，CFFF 方板自由端中点位移 present 为 `-5.9976 mm`，COMSOL 为 `-5.9525 mm`，文中位移偏差为 `0.76%`。
- 用当前 case 文件节点表 `cases/Thermal_CFFF_U_Vf0.6-30x30-10layer.txt` 和旧 `output/static_elastic_U_Vf60_elastic.mat` 的 `Qd` 还原后，我们自由端中点位移为 `-5.99822273188 mm`；对钱沈云 present 的误差为 `0.010383%`，对钱沈云 COMSOL 的误差为 `0.768127%`。
- 钱沈云代码里确实存在同几何、同网格、同载荷的入口：CFFF 方板、300 mm × 300 mm × 6 mm、30×30、10 层、`Loadmax = -15000`。
- 这个入口块在 `MEET_CFFF_thermal.m` 中是注释块；当前活动块不是方板，而是 CFFF 圆柱壳，`Loadmax = -2000`。
- 已有 `.fig` 结果能抽出曲线，但抽到的是温差/热载荷位移曲线，不是 15000 Pa 机械力同工况曲线。
- 赵亚飞材料里有力载荷脚本和位移相关文件，但活动工况主要是 SSSS、圆柱、频率/热载荷或孔隙问题，不能直接替代当前 U/Vf0=0.6/CFFF 方板 Case A。
- 之前用 `output/LINEAR_DataUsed_runtime.txt` 失败，是因为该运行缓存被别的工况覆盖；改用权威输入文件 `NODE START` 后，`Qd=13800` 与节点自由度完全匹配。
- 2026-06-12 追加：复用钱沈云同工况复跑缓存 `qian_point3_cfff_plate_direct.mat`，与我们 `output/static_elastic_U_Vf60_elastic.mat` 比较，13800 个约束后机械自由度最大差异为 `0`，15 个取点最大差异也为 `0`。

因此，当前能写成：

> 加力产生位移的计算链路已经通过我们自己的 MATLAB/COMSOL 独立对照验证，原始 15 点对 COMSOL 3D solid 的最大误差为 4.93%；同时，在钱沈云论文同几何、同载荷的自由端中点上，我们的还原结果为 -5.9982 mm，论文 present 为 -5.9976 mm，误差约 0.01%，对论文 COMSOL 误差约 0.77%。进一步用钱沈云代码同工况复跑后，13800 个机械自由度和 15 个取点均与我们当前结果完全一致。因此第 1 点可以写成“与钱沈云论文单点和钱沈云代码同工况结果均已对上”，但 15 点局部 COMSOL 误差仍需解释。

不能写成：

> 第 1 点全部 15 个点和 COMSOL 3D solid 逐点误差都在 3% 内。

## 我们当前可用数值

来源：`outputs/manual-20260611-fgmeet/force-displacement-validation/recomputed_validation_summary.csv`

| 工况 | MATLAB 中心位移 | COMSOL 中心位移 | 中心误差 | 15 点最大误差 | 平均误差 |
|---|---:|---:|---:|---:|---:|
| U/Vf0=0.6/CFFF/Case A，原始 3D solid | -2.127520 mm | -2.207739 mm | 3.7706% | 4.9268% | 3.5128% |
| U/Vf0=0.6/CFFF/Case A，最优统一刚度缩放 1.021505 | -2.127520 mm | -2.161273 mm | 1.5865% | 2.7184% | 1.9390% |

说明：`1.021505` 是由 15 点原始 COMSOL/MATLAB 位移比例范围 `0.993742~1.049268` 推出的最优统一刚度缩放，可解释“如何进入 3% 内”；但它不是原始 COMSOL 结果，也不是钱沈云论文表格结果。

COMSOL 3% 边界说明：`outputs/manual-20260611-fgmeet/force-displacement-validation/comsol_3pct_boundary_explanation.md`

新增自由端中点外部对照：

| 对比 | 我们结果 | 外部结果 | 相对误差 | 判断 |
|---|---:|---:|---:|---|
| 我们 vs 钱沈云 present Table 3 | -5.99822273188 mm | -5.9976 mm | 0.010383% | 对上 |
| 我们 vs 钱沈云 COMSOL Table 2 | -5.99822273188 mm | -5.9525 mm | 0.768127% | 对上 |

来源：`outputs/manual-20260611-fgmeet/qian-force-displacement/our_free_end_midpoint_vs_qian_table23.csv`

新增钱沈云代码同工况 15 点对照：

| 对比 | 最大差异 | 判断 |
|---|---:|---|
| 13800 个机械自由度，钱沈云复跑 `Qd` vs 我们 `Qd` | `0 m` | 完全一致 |
| 15 个取点，钱沈云复跑 vs 我们结果 | `0 mm` | 逐点完全一致 |

来源：

- `outputs/manual-20260611-fgmeet/qian-force-displacement/qian_vs_our_force_qd_summary_from_cache.csv`
- `outputs/manual-20260611-fgmeet/qian-force-displacement/qian_vs_our_force_15points_from_cache.csv`
- `outputs/manual-20260611-fgmeet/qian-force-displacement/compare_qian_force_qd_from_cache.m`

## 钱沈云材料核对

文件：`reference/predecessor-code/qian-shenyun/双向耦合程序-new/双向耦合程序-new/MEET-elastic-thermal/MEET_CFFF_thermal.m`

论文机械载荷表格：

| 来源 | 工况 | 模型 | 网格/自由度 | 自由端中点位移 | 用途 |
|---|---|---|---|---:|---|
| 钱沈云 2026 Table 2 | CFFF 方板，15000 Pa 均布载荷 | COMSOL 3D solid | 45×45×10 / 443829 DOF | -5.9525 mm | 外部 COMSOL 基准 |
| 钱沈云 2026 Table 3 | CFFF 方板，15000 Pa 均布载荷 | present shell model | 6×6 / 960 DOF | -5.9976 mm | 外部 present 基准 |
| 钱沈云 2026 正文 | 同上 | present vs COMSOL | 6×6 vs 45×45×10 | 偏差 0.76% | 证明文献机械力位移可达 1% 内 |

证据表：`outputs/manual-20260611-fgmeet/qian-force-displacement/qian_mechanical_table23_evidence.csv`

已定位到的同工况注释块：

| 证据 | 内容 |
|---|---|
| 活动入口 | 第 9 行当前为 `Thermal_CFFFcylinder_0.6Vf-20x20-10layer.txt`，不是方板 |
| 当前活动载荷 | 第 193 行为 `Loadmax = -2000` |
| 方板 30×30 入口 | 第 400-402 行为 CFFF 300 mm 方板 30×30 中心线取点 |
| 方板载荷 | 第 419 行为 `Loadmax = -15000` |
| 求解口径 | 第 452-455 行使用 `AA=[KuuT,KutT; KtuT,KttT]`、`BB=[FueT; FutT]`、`Qd = CC(1:Tot_DOF_MEET)` |
| 输出口径 | 第 461-462 行将 `Qd(PositionMx/PositionMy)` 转成 mm |

这个块和我们当前“力 -> 位移”的口径是对应的，但因为它被注释，仓库里没有同步给出该块跑出来的位移 CSV/MAT 结果。

## 我们自由端中点提取尝试

目标是取我们当前 `x=0.30, y=0.15, z=0` 自由端中点，与钱沈云 Table 3 的 `-5.9976 mm` 做单点对照。

| 尝试 | 结果 | 判断 |
|---|---|---|
| 用旧 `output/static_elastic_U_Vf60_elastic.mat` + 当前 `output/LINEAR_DataUsed_runtime.txt` | `Qd=13800`，节点表可还原自由度为 13495 | 缓存不匹配，不能硬拼 |
| 用旧 `.mat` + `matlab/meet-elastic-thermal/LINEAR_DataUsed.txt` | 自由度可匹配 13800，但坐标为 `z=0.6`，没有当前方板 `z=0` 点 | 不是同一方板坐标表 |
| 重新运行 `run_meet_static(..., 'OutTag','U_Vf06_elastic_rerun_20260612')` | 当时 MATLAB 报 5201，未生成新 `.mat` | 后续 MATLAB 服务已恢复，并已用于钱沈云同工况复跑 |
| 用旧 `.mat` + 当前 case 文件 `NODE START` | 自由度匹配 13800，目标点存在 | 成功，得到 `-5.99822273188 mm` |

详细表：`outputs/manual-20260611-fgmeet/qian-force-displacement/free_end_midpoint_extraction_attempt.csv`

可复现脚本：`outputs/manual-20260611-fgmeet/qian-force-displacement/extract_our_free_end_midpoint.py`

## 已抽取的 `.fig` 曲线

抽取脚本：`outputs/manual-20260611-fgmeet/qian-force-displacement/extract_mat_fig_curves.py`

曲线摘要：`outputs/manual-20260611-fgmeet/qian-force-displacement/fig-curves/qian_fig_curve_summary.csv`

关键发现：

| 文件 | 曲线特征 | 是否能作为机械力同工况 |
|---|---|---|
| `不同温度变化分布下中心线位移比较图.fig` | UTR/LTR/STR/HC，x=0~0.2，含“文献”曲线，位移量级约 -0.7 到 -2.05 | 不能；是不同温度变化分布对比 |
| `CFFF-FG-MEEP方形板热传导温差.fig` | x=0~0.2，y 量级约 -0.002 m | 不能；热传导温差 |
| `CFFF-FG-MEEP方形板线性温差.fig` | x=0~0.2，y 量级约 -0.00194 m | 不能；线性温差 |
| `MEET_CFFFLRT56_G2.fig` | x=0~0.3，但 y 量级约 4e-05，且不是机械载荷输出 | 不能；不是 15000 Pa 方板机械结果 |

## 赵亚飞材料核对

相关目录：`reference/predecessor-code/zhao-yafei/MEET/MEET/FG-MEEP-LIN-frequency-displacement`

| 文件 | 证据 | 判断 |
|---|---|---|
| `FG_MEEP_load_stastic.m` | 活动 `InputFile` 为 `FG-MEEP-B/SSSS-FG-MEEP-X.txt`，`PositionM` 注释为 SSSS 中心线，`LoadMax=2e6` | 不是我们的 CFFF 方板 15000 Pa |
| `FG_MEEP_Frequency_CFFF_UVOX.m` | 活动块为 `CFFF-V-index-2-P-0.2.txt`，但 `LoadMax=0`，求解 `Qd = KuuT\FutT`；主要保存频率 | 不是机械力位移结果 |
| `CFFF-U-index-2-P-0.2.txt` | 输入文件头为 `CYLINDER`、`MFC` | 不是当前 CFFF 方板工况 |

所以赵亚飞材料目前只能作为后续方法/文献背景，不能用于第五点的同工况数值验证。

## 当前建议

汇报时把这一点写成“已完成钱沈云论文自由端中点核对，也完成钱沈云代码同工况 15 点/全自由度核对；COMSOL 3D solid 的 15 点局部误差仍需要解释”。不要把 1.0215 刚度敏感性包装成师姐结果，也不要说 COMSOL 15 点全部已经 3% 内。

下一步如果要进一步增强第 1 点，只剩 COMSOL 解释工作：

1. 说明我们和钱沈云代码完全一致，4.93% 来自我们与 COMSOL 3D solid 的建模/网格/等效刚度差异；
2. 保留最优统一刚度缩放 `1.021505` 后 15 点最大误差 `2.72%` 作为“进入 3% 的边界证据”，但不要把它说成原始 COMSOL 或钱沈云论文表格结果。
