# 第三点：位移回代电势/磁势新口径核查

更新时间：2026-06-12

## 结论

第三点现在已经完成钱沈云同工况代码复跑核对：旧 `output/coupling_validation_2mm.csv` 的过期 2 mm 数字已经被新中心位移口径替换，前人 `.mat/.fig` 结果文件也已经完成变量级静态盘点；虽然现有论文/结果文件没有直接给出 `Y_SensM_E/Y_SensM_M` 表格，但使用钱沈云入库代码复跑 CFFF 30x30x10 方板后，按当前层平均 span 口径已经和我们结果对上。

当前可写成：

> 位移回代电势/磁势的矩阵入口已经确认，旧 2 mm 表的缩放口径已经修正。按当前中心位移口径，机械 2 mm 对应 `load_scale=-14100.9259357`，回代电势层平均 span 为 `658.585489735105`，回代磁势层平均 span 为 `0.681570500460290`。钱沈云同工况代码复跑得到 `658.585489735107` 和 `0.681570500460291`，差异在 `1E-12` 量级，因此第三点可写成“钱沈云代码同工况验证已完成”。

不能写成：

> 第三点已经在钱沈云论文表格或 COMSOL 结果中直接验证。

## 新口径 2 mm 表

来源：`outputs/manual-20260611-fgmeet/electro-magneto-validation/current_coupling_2mm_recalibrated.csv`

| 检查项 | 当前驱动量 | 探针响应 | 生成量 | 说明 |
|---|---:|---:|---:|---|
| 力 -> 2 mm | `-14100.9259357 load_scale` | `-2.1275198619 mm` at `-15000` | - | 替换旧 `-83134.1788268` |
| 电压 -> 2 mm | `11481.6945115 V` | `-0.0522570949 mm` at `300 V` | - | 与第二点新口径一致 |
| 磁势 -> 2 mm | `2291.1377731 A` | `0.1745857472 mm` at `200 A` | - | 与第二点新口径一致 |
| 2 mm 位移 -> 电势 span | `-14100.9259357 load_scale` | `-15000` 载荷下层平均 span `700.5768551` | `658.5854897` | 已与钱沈云代码复跑对应 |
| 2 mm 位移 -> 磁势 span | `-14100.9259357 load_scale` | `-15000` 载荷下层平均 span `0.7250273885` | `0.6815705005` | 已与钱沈云代码复跑对应 |

内部重标定脚本：`outputs/manual-20260611-fgmeet/electro-magneto-validation/recalibrate_coupling_2mm_current_center.py`

钱沈云同工况复跑脚本：`outputs/manual-20260611-fgmeet/electro-magneto-validation/run_qian_point3_cfff_plate_direct.m`

## 外部材料核查

已抽取钱沈云电/磁目录下的 `.fig`：

`outputs/manual-20260611-fgmeet/electro-magneto-validation/qian-electro-magneto-fig-curves/qian_fig_curve_summary.csv`

结果：

- `CFFF位移to温差-位移图.fig` 能抽出两条 `x=0~0.3` 曲线，y 量级约 `-4.65` 到 `-5.49`，看起来是“位移到温差/位移图”相关，不是电势或磁势回代表。
- `MEET_CFFFLRT56_G2.fig`、`MEET_CFFFRVK5_G2.fig` 与当前第 3 点同工况电/磁势回代没有明确对应关系。
- 目前没有找到可以直接作为“位移 -> 电势/磁势”的钱沈云外部数值表。

2026-06-12 追加静态盘点：

- 已生成变量级清单：`outputs/manual-20260611-fgmeet/electro-magneto-validation/predecessor_mat_variable_inventory.csv`，覆盖钱沈云/赵亚飞材料下 `293` 个 `.mat/.fig` 文件、`437` 条顶层变量记录。
- 精确 `Sens*` 变量只发现 `reference/predecessor-code/qian-shenyun/双向耦合程序-new/双向耦合程序-new/MEET-elastic-thermal/CurrentComp/CFFF_SensM_T.mat` 中的 `SensM_T sparse 9000x1`，这是温度/热响应输出，不是电势/磁势。
- 没有发现顶层变量 `SensM_E`、`SensM_M`、`Y_SensM_E`、`Y_SensM_M`。
- 钱沈云 `Main_StaticNL851T5T56MEEP_RWR_V4.m` 第 237-245 行确认会回代 `SensM_E/SensM_M`，第 301-303 行确认会放进 `XY_Value`，但仓库现有结果文件没有保存这个 `XY_Value`。
- 赵亚飞 `FG_MEEP_Thermal_output_pointial.m` 也有 `SensM_E/SensM_M` 和层平均 `SensMag_M` 的算法例子，但活动输入为 `SSSS-FG-MEEP-U.txt`，不是当前 CFFF 方板同工况，且未发现对应保存结果。
- 已整理外部候选证据清单：`outputs/manual-20260611-fgmeet/electro-magneto-validation/point3_external_candidate_inventory.csv`。

2026-06-12 追加复跑：

- MATLAB 5201 服务问题已恢复，`whos -file` 和钱沈云 30x30 同工况复跑均可执行。
- 前人 `Main_FOSDLIN851T5MEET_V4.m` 末尾有误写 `ss`，本次只在输出目录增加 no-op `matlab-helpers/ss.m`，未修改前人源码。
- 钱沈云 CFFF 30x30x10 方板复跑得到 `final_dof_m=13800`、`final_dof_mee=9000`，自由端中点 `-5.99822273187996 mm`，中心位移 `-2.12751986193692 mm`。
- 复跑比较表：`outputs/manual-20260611-fgmeet/electro-magneto-validation/qian_point3_vs_current_comparison.csv`。
- 按当前层平均 span 口径，电势 2 mm span 差异 `1.14E-12`，磁势 2 mm span 差异 `1.33E-15`。

## 当前状态

第三点现在是：

- 内部公式/矩阵入口：已确认；
- 旧 2 mm 表：已判定过期；
- 新 2 mm 口径：已重标定并与钱沈云代码复跑对上；
- 前人结果文件静态盘点：已完成，未发现同工况电势/磁势回代输出；
- 外部核对：钱沈云代码同工况复跑已完成；论文/COMSOL 直接表格仍未发现。

下一步如果导师要求“论文表格/COMSOL 直接证据”，仍需要师姐导出 `Y_SensM_E/Y_SensM_M` 或对应 `.fig/.mat/.csv`；如果接受“钱沈云同代码同工况复跑”，第三点已经可以闭合。
