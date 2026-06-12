# 第4、5点进度核对

更新时间：2026-06-12

## 总结论

第 4、5 点已经完成对齐，可以进入本周汇报材料。

- 第 4 点已经从“只列计算结果”改成“验证矩阵”：每个结果都给出我们程序、外部来源、误差、状态、禁写口径和下一步。
- 第 5 点已经从“泛泛按周推进”改成“三周交付节奏”：第 1 周讲力到位移，第 2 周讲电压/磁势到位移，第 3 周讲位移回代电势/磁势。
- 第 4、5 点的主文件是 `five_point_validation_matrix.csv` 和 `five_point_content_update.md`；第 1、2、3 点的证据文件已经在矩阵中逐项引用。

## 第4点核对

导师要求：工作不是只算数据，要说明数据对不对。

当前对齐结果：

| 验证项 | 对齐状态 | 可讲口径 |
|---|---|---|
| 力 -> 位移 | 已列入验证矩阵 | 钱沈云论文自由端单点、钱沈云代码同工况 15 点零差异、COMSOL 原始 4.93% 与最优刚度边界 2.72% 分开讲。 |
| 电压 -> 位移 | 已列入验证矩阵 | 钱沈云论文 Table 4 对上，误差约 0.08%。 |
| 磁势 -> 位移 | 已列入验证矩阵 | 钱沈云论文 Table 5 对上，对 present 约 0.24%，对 COMSOL 约 0.92%。 |
| 位移 -> 电/磁势 | 已列入验证矩阵 | 钱沈云代码同工况复跑对上，层平均 span 差异约 `1E-12` 量级。 |

当前边界：

- 不能把第一点写成“COMSOL 3D solid 原始 15 点天然全部进入 3%”。
- 不能把第三点写成“钱沈云论文表格或 COMSOL 直接验证”，因为当前依据是钱沈云代码复跑。
- 参数扫描、孔隙、动力结果应放在验证闭环之后，作为附录或后续工作。

## 第5点核对

导师要求：前三点按周推进，第一周先讲加力验证位移。

当前对齐结果：

| 周次 | 主线 | 当前可交付 |
|---|---|---|
| 第 1 周 | 力 -> 位移 | 钱沈云论文自由端中点、钱沈云代码 15 点零差异、COMSOL 原始 4.93% 和刚度边界 2.72%。 |
| 第 2 周 | 电/磁 -> 位移 | 钱沈云论文 Table 4/Table 5 对照表；300 V 和 200 A 正向致变形已经基本对上。 |
| 第 3 周 | 位移 -> 电/磁势 | 钱沈云代码同工况复跑误差表；电势和磁势 span 差异约 `1E-12` 量级。 |

推荐本周汇报顺序：

1. 先讲第 4 点的验证矩阵，说明现在每个结果都能追到来源、误差和状态。
2. 再按第 5 点节奏展开：本周重点放第 1 周力到位移，电/磁和回代作为后两周已准备好的支撑材料。
3. 最后明确禁写边界：第一点 COMSOL 原始 15 点最大误差仍是 4.93%，第三点是代码复跑验证，不是论文直接表格。

## 已对齐文件

- `outputs/manual-20260611-fgmeet/five-point-update/five_point_validation_matrix.csv`
- `outputs/manual-20260611-fgmeet/five-point-update/five_point_content_update.md`
- `outputs/manual-20260611-fgmeet/force-displacement-validation/comsol_3pct_boundary_explanation.md`
- `outputs/manual-20260611-fgmeet/electro-magneto-validation/qian_point3_direct_rerun_check.md`
- `outputs/manual-20260611-fgmeet/qian-force-displacement/qian_force_displacement_check.md`
