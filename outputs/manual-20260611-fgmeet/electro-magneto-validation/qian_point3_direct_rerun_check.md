# 第三点钱沈云同工况复跑核对

更新时间：2026-06-12

## 结论

第三点现在可以从“内部重标定”升级为“钱沈云代码同工况复跑已对上”。这不是论文表格直接给出的数值，而是使用钱沈云入库代码和同一 CFFF 30x30x10 方板工况复跑得到的程序级外部验证。

关键结果：

| 指标 | 钱沈云代码复跑 | 我们当前表 | 差值 | 相对差异 |
|---|---:|---:|---:|---:|
| 2 mm 位移回代电势层平均 span | `658.585489735107` | `658.585489735105` | `1.14E-12` | `1.73E-13%` |
| 2 mm 位移回代磁势层平均 span | `0.681570500460291` | `0.681570500460290` | `1.33E-15` | `1.95E-13%` |

因此，按我们当前 `current_coupling_2mm_recalibrated.csv` 的汇报口径，第三点已经和钱沈云同工况代码输出对应上。

## 复跑口径

复跑脚本：

- `outputs/manual-20260611-fgmeet/electro-magneto-validation/run_qian_point3_cfff_plate_direct.m`
- `outputs/manual-20260611-fgmeet/electro-magneto-validation/matlab-helpers/ss.m`

钱沈云入口：

- `reference/predecessor-code/qian-shenyun/双向耦合程序-new/双向耦合程序-new/MEET-elastic-thermal/InputFile/Thermal_CFFFplate_0.6Vf-30x30-10layer.txt`
- `reference/predecessor-code/qian-shenyun/双向耦合程序-new/双向耦合程序-new/SubFunMFC/Main_FOSDLIN851T5MEET_V4.m`
- 回代公式与 `Main_StaticNL851T5T56MEEP_RWR_V4.m` 第 237-245 行一致。

说明：

- 前人 `Main_FOSDLIN851T5MEET_V4.m` 末尾有一个误写的 `ss`，会导致函数算完后无法返回；本次只在输出目录加了 no-op `ss.m` 并优先加入 MATLAB path，没有改前人源码。
- 30x30 矩阵已缓存到 `qian_point3_cfff_plate_matrices.mat`，后续重跑无需重新装配。

## 关键数值

来源：`outputs/manual-20260611-fgmeet/electro-magneto-validation/qian_point3_cfff_plate_summary.csv`

| 指标 | 数值 |
|---|---:|
| `final_dof_m` | `13800` |
| `final_dof_mee` | `9000` |
| 自由端中点位移 | `-5.99822273187996 mm` |
| 当前中心位移口径 `center_my` | `-2.12751986193692 mm` |
| 2 mm 缩放系数 | `0.940061729049701` |
| 电势层平均 span，15000 Pa | `700.576855097446` |
| 电势层平均 span，缩放到 2 mm | `658.585489735107` |
| 磁势层平均 span，15000 Pa | `0.725027388519777` |
| 磁势层平均 span，缩放到 2 mm | `0.681570500460291` |

## 口径差异

本次脚本同时输出了两个口径：

| 口径 | 电势 2 mm span | 磁势 2 mm span | 是否用于当前汇报 |
|---|---:|---:|---|
| `zero_delta_full_span`：外加温差为 0，取全场 `SensM_E/SensM_M` 最大最小 | `982.425092612064` | `0.759433824648604` | 不用于当前表 |
| `thermal_response_layer_span`：热响应参与回代，按 10 层平均后取 span | `658.585489735107` | `0.681570500460291` | 用于当前表 |

旧内部表使用的是第二种“层平均 span”口径，所以之前看起来和全场 span 不一致，并不是回代公式错误。

## 当前可写结论

推荐写：

> 位移回代电势/磁势已经用钱沈云同工况代码完成复跑。钱沈云 CFFF 30x30x10 方板在 15000 Pa 下得到中心位移 `-2.1275199 mm`，与我们当前中心位移完全一致；按当前 2 mm 和层平均 span 汇报口径，钱沈云复跑的电势 span 为 `658.5854897`、磁势 span 为 `0.6815705005`，与我们当前表差异约 `1E-12` 量级。因此第三点可以作为“同工况代码验证已完成”。

不要写：

> 第三点已经在钱沈云论文表格或 COMSOL 结果中直接验证。

因为现有论文和入库结果文件没有直接给出这组 `Y_SensM_E/Y_SensM_M` 表格；本次闭环依据是钱沈云入库代码复跑。
