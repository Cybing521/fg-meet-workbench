# FG-MEE 补充需求复核表（2026-07-18）

复核对象：`fgmee_latest_feasible_results_report_20260715.tex/.pdf`。本表按用户提供的四张截图逐项核对，并以仓库内 MATLAB/COMSOL 源码和原始 CSV 为判定依据。

| 编号 | 用户要求 | 报告落点 | 核验结论 |
|---|---|---|---|
| R1 | 说明电等效应力对应的电势 | 第 2.1、4.1 节 | 已明确：每个 0.6 mm 外侧活动层的电势差幅值为 300 V；直接场复算中外表面为 300 V、相邻内界面为 0 V。 |
| R2 | 说明磁等效应力对应的磁势 | 第 2.1、4.1 节 | 已明确：每个外侧活动层的磁标势差幅值为 200 A；该单位表示磁标势，不是 200 A 电流。 |
| R3 | 给出势差到等效应力的公式 | 第 4.1 节 | 已给出 $E_3=-\partial\phi/\partial z$、$H_3=-\partial\psi/\partial z$、$\boldsymbol\sigma^E=-\mathbf e^{\mathsf T}\mathbf E$、$\boldsymbol\sigma^H=-\mathbf q^{\mathsf T}\mathbf H$ 及 $\mathbf e=\mathbf d\mathbf C$，并完成数值代入。 |
| R4 | 核对是否为 CFFF、尺寸是否为 30 mm×30 mm×6 mm | 第 4.1 节 | 已明确纠正：同构平板为 CFFF 300 mm×300 mm×6 mm，不是 30 mm×30 mm×6 mm。 |
| R5 | 明确单元、积分、网格和厚度离散 | 第 2.4、4.1 节 | 已说明 MATLAB H20 与 3×3×3 全积分、COMSOL 二次巧凑实体及映射—扫掠网格；10/15/20 为面内划分，厚度恒为 10 个单元。 |
| R6 | 明确中心点和自由端中点探针 | 第 4.1 节、图 1 | 已给出平板物理坐标 (0.15,0.15,0) m 和 (0.30,0.15,0) m，并说明 COMSOL 自由端采用 $L-10^{-9}$ m 内偏取值。曲壳正式输出仍为中心探针。 |
| R7 | 补出自由端中点六组 MATLAB/COMSOL 原始数据 | 第 4.2 节表 7 | 已列出电/磁两类载荷、10/15/20 三档网格的六组两软件位移和相对差；自由端最大相对差为 $1.2127\times10^{-4}\%$。 |
| R8 | 增加几何、材料、边界和施加载荷图 | 第 2.1 节图 1、图 2 | 已包含 CFFF 边界、15 kPa 真实法向压力、U/X 十层分布及外层电势/磁标势边界；场箭头以不同线型并直接标注 $E_3/H_3$。 |
| R9 | 给出 R=1.0、0.4、0.3、0.2 m 四张圆柱壳示例图 | 第 2.1 节图 1 | 已用统一物理尺度绘制四个子图，并标注半径、圆心角、固支/自由边、压力和位置标记。 |

## 关键证据

- 同构平板几何、CFFF、H20、网格与双探针：`matlab/run_isomorphic_solid_cfff.m`、`tools/comsol/RunIsomorphicSolidCfffValidation.java`。
- 压电系数转换 $\mathbf e=\mathbf d\mathbf C$：`matlab/meet-fem-core/SF_GetMatePropMEEP.m`。
- 直接电势边界：`tools/comsol/RunDirectElectroCfffValidation.java`。
- 直接磁标势、$H_3=-\partial\psi/\partial z$ 与 $\boldsymbol\sigma^H=-\mathbf q^{\mathsf T}\mathbf H$：`tools/comsol/RunDirectMagneticCfffValidation.java`。
- 双探针六组原始结果：`outputs/paper-20260715-fgmee/experiments/isomorphic_solid/isomorphic_solid_cross_solver_comparison.csv`。
- 曲壳几何、固支面与法向压力：`tools/generate_curvature_fg_cases.py`、`tools/comsol/RunCurvedSolidCfffValidation.java`。

## 最终结论

九项需求均已落实。复核同时修正了两项图形问题：二维载荷示意改用真实圆截面以保证压力箭头严格法向；三维曲壳中的压力箭头和中心标记已外移、加粗，避免在正文尺寸下被曲面遮挡。报告只把 4.934 MPa 表述为沿用的历史等效载荷数值，不再把 4.934 MPa 与按当前四位材料系数回算的 4.9358 MPa 之差唯一归因于舍入。
