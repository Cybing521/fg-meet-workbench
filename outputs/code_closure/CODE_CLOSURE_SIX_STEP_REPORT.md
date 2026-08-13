# FG-MEE 反向感知代码闭环：六步执行与核对报告

生成日期：2026-07-20  
工作区：`G:\fg-meet-workbench`

## 结论先行

本轮修改的是本项目当前 MATLAB/COMSOL 实现，不是钱沈云参考目录中的代码，也不能据此推出钱沈云论文的全部结果错误。钱沈云相关旧程序和公开结果只用于问题定位与数值对照，正确性由本项目自己的矩阵推导、回归测试、MATLAB 网格复算、独立 COMSOL 四场求解及交付门禁共同核验。

六步已经全部完成并通过。最终代码闭环包不再携带与当前实现结论冲突的 20260715 旧报告；交付范围只保留可运行代码、正式输入、原始数值证据、代表模型、本六步报告及哈希清单。

## 第 1 步：把热释电/热释磁项改为逐物理层组装

### 1.1 原问题

旧单元路径在处理第 \(\ell\) 个物理层时，把该层热释系数写入全部活动势自由度，然后主装配又对所有物理层累加。设活动层数为 \(m\)，旧写法等价于

\[
\mathbf P_{\rm old}=\sum_{\ell=1}^{m}p_\ell\mathbf I_m,
\qquad
\mathbf T_{\rm old}=\sum_{\ell=1}^{m}t_\ell\mathbf I_m.
\]

均匀十层时，每个对角项因此被累计十次。这个问题不能通过最终结果简单除以 10 普遍修复，因为机械项、热项和磁电项在同一个线性系统中共同作用；对非均匀或部分活动层，全局除层数在数学上更不成立。

### 1.2 当前修复

现在材料例程只写当前活动层：

\[
P_{ij}=p_\ell\,\delta_{i\ell}\delta_{j\ell},
\qquad
T_{ij}=t_\ell\,\delta_{i\ell}\delta_{j\ell}.
\]

对应源码：

- `matlab/meet-fem-core/SF_GetMatePropMEEP.m`：`p(MEELayIndex,MEELayIndex)=PyroE`、`t(MEELayIndex,MEELayIndex)=PyroM`；
- `matlab/meet-fem-core/SF_ElemComptLIN851T5MEEP_V4.m`：直接用当前层 `Mate_p/Mate_t` 形成 `HpE/HpM`；
- `matlab/run_meet_static.m`：删除旧的全局 `/nLayer` 补偿，明确 `pyro_assembly_mode='layer_local'` 和 `solver_revision='layer_local_pyro_v3'`。

同一 10×10 网格的历史旧输出与当前正式输出如下。历史值只用于缺陷回归，不进入正式门禁。

| 目标位移/mm | 历史旧电势/V | 当前电势/V | 电势下降/% | 历史旧磁势/A | 当前磁势/A | 磁势下降/% |
|---:|---:|---:|---:|---:|---:|---:|
| 0.5 | 164.544443 | 78.431689 | 52.3340 | 0.170287139 | 0.030880910 | 81.8654 |
| 1.0 | 329.088887 | 156.863379 | 52.3340 | 0.340574277 | 0.061761819 | 81.8654 |
| 2.0 | 658.177773 | 313.726757 | 52.3340 | 0.681148555 | 0.123523638 | 81.8654 |

## 第 2 步：修正层映射、凝聚、探针和各向异性项，并做回归测试

本步不是只改一个系数，而是把可能继续污染正式结果的四个结构性问题一起封闭：

1. `SF_Condensation.m` 建立显式“物理层 → 紧凑 MEE 层”映射，删除中间非活动层时不再误删后续层；所有电、磁、热及交叉块的相同行列同步凝聚。
2. `build_active_layer_dof_map.m` 统一边界势、层平均和输出所用的活动层自由度编号。
3. `interpolate_shell_dof_at_point.m` 用八节点 Serendipity 形函数在几何中心插值，不再以最近节点冒充几何中心。
4. `SF_GetMatePropMEEP.m` 中 \(g_{33}\) 修正为 `d31*eM(:,1)+d32*eM(:,2)`；旧代码第二项错误重复使用 `eM(:,1)`。各向异性回归算例的正确值为 93.2203389830509，旧索引会给出 62.7118644067797。

最终 MATLAB 测试命令：

```powershell
matlab -batch "addpath(pwd); results = runtests('tests/matlab'); disp(results); assertSuccess(results);"
```

结果：`10 Passed, 0 Failed, 0 Incomplete`。

## 第 3 步：按网格独立重算 MATLAB 正式结果

执行入口：`run_matlab_inverse_pyro_fix_verification.m`。10/15/20/30 四档网格各自重新组装并求解一次机械—热及电—磁系统，`UseCache=false`；每个网格内的 0.5/1.0/2.0 mm 三个目标利用线性系统的精确比例关系由该网格自身基准解缩放。因此“四档网格是独立求解”，但“三个位移不是每档三次独立 MATLAB 求解”，不能混写。

正式证据：`outputs/code_closure/inverse_sensing/matlab_inverse_structural_pyro_mesh.csv`。

| 面内网格 | 0.5 mm 电势/V | 0.5 mm 磁势/A | 相邻网格电势变化/% | 状态 |
|---:|---:|---:|---:|---|
| 10×10 | 78.431689371 | 0.0308809096 | — | ok |
| 15×15 | 78.453286433 | 0.0308894130 | 0.027536 | ok |
| 20×20 | 78.467891998 | 0.0308951636 | 0.018617 | ok |
| 30×30 | 78.480274839 | 0.0309000391 | 0.015781 | ok |

30×30 的 0.5/1.0/2.0 mm 结果分别为 78.480274839、156.960549679、313.921099358 V，以及 0.0309000391、0.0618000782、0.1236001565 A。该线性比例是线性方程组的预期性质，不是三个独立统计样本。

## 第 4 步：核对求解状态、残差、后向误差和条件数

MATLAB 实际求解顺序为

\[
\begin{bmatrix}\mathbf K_{uu}&\mathbf K_{uT}\\
\mathbf K_{Tu}&\mathbf K_{TT}\end{bmatrix}
\begin{bmatrix}\mathbf u\\\mathbf T\end{bmatrix}
=\begin{bmatrix}\mathbf f\\\mathbf 0\end{bmatrix},
\]

随后求开路传感块

\[
\begin{bmatrix}\mathbf K_{\phi\phi}&\mathbf K_{\phi\psi}\\
\mathbf K_{\psi\phi}&\mathbf K_{\psi\psi}\end{bmatrix}
\begin{bmatrix}\boldsymbol\phi\\\boldsymbol\psi\end{bmatrix}
=-
\begin{bmatrix}
\mathbf K_{\phi u}\mathbf u+\mathbf K_{\phi T}\mathbf T\\
\mathbf K_{\psi u}\mathbf u+\mathbf K_{\psi T}\mathbf T
\end{bmatrix}.
\]

| 网格 | 机械—热相对残差 | 机械—热后向误差 | 机械—热 rcond | 传感相对残差 |
|---:|---:|---:|---:|---:|
| 10×10 | 6.2655e-11 | 3.2673e-21 | 1.5900e-14 | 2.9668e-16 |
| 15×15 | 1.2862e-10 | 1.9777e-21 | 6.8579e-15 | 2.8268e-16 |
| 20×20 | 2.3060e-10 | 1.4926e-21 | 3.9972e-15 | 3.2554e-16 |
| 30×30 | 5.2003e-10 | 9.9544e-22 | 1.7132e-15 | 2.8969e-16 |

残差和后向误差通过，说明计算得到的向量很好地满足已组装离散方程。但 30×30 的 `rcond≈1.71e-15` 表明机械—热矩阵高度病态，所以不能把小残差等同为同量级的前向解精度保证。网格结果仍平滑收敛，但条件数风险必须保留在报告中。

## 第 5 步：运行独立 COMSOL 十层块三角四场验证

正式源码：`tools/comsol/RunBlockTriangularInverseSensorCfffValidation.java`。模型包含 10 个三维实体层、固体位移场，以及每层独立的电势、磁标势和互易温度弱式自由度；开路电、开路磁和绝热条件由自然零通量边界实现，各势场仅固定一个规范点。耦合采用与 MATLAB 一致的块三角关系：机械—热先决定结构状态，传感势不反馈到机械块，但 \(\phi/\psi/T\) 是有限元未知量，不是求解结束后的代数复制。

正式运行共 7 个 Stationary solve：3 个通道隔离、1 个载荷归一化、3 个目标位移独立重求。求解器保持 COMSOL 默认 Direct 错误检查，稳态相对容差 \(10^{-4}\)，分离式固定 25 次外层迭代，并在结束后对四场最终组误差和 LinRes 施加 \(10^{-5}\) 硬门禁。相关属性用法依据 [COMSOL 6.0 Programming Reference Manual](https://doc.comsol.com/6.0/doc/com.comsol.help.comsol/COMSOL_ProgrammingReferenceManual.pdf)。

正式模型源码 SHA-256：`a42bc3aa158cdb948719c409a89eef88f51aafcd3586a8e2fb236298ec4609d1`，与所有正式 CSV 中的 `source_sha256` 一致。

### 5.1 COMSOL 硬门槛

| 检查项 | 实值 | 门槛 | 结果 |
|---|---:|---:|---|
| 机械全局力平衡残差 | 4.7003e-14 | ≤1e-6 | 通过 |
| 电场弱矩残差 | 1.2199e-15 | ≤1e-6 | 通过 |
| 磁场弱矩残差 | 4.3264e-15 | ≤1e-6 | 通过 |
| 温度弱矩残差 | 6.4770e-18 | ≤1e-6 | 通过 |
| 四场最终分离组误差最大值 | 7.6e-11 | ≤1e-5 | 通过 |
| 四场最终 LinRes 最大值 | 5.7e-14 | ≤1e-5 | 通过 |
| 通道隔离 | electric/magnetic/thermal 均 pass | 必须全部 pass | 通过 |
| COMSOL `hasProblems()` | false | 必须 false | 通过 |

正式状态为 `completed_full_field`，证据等级字段为 `A_independent_block_triangular_fields`。

### 5.2 MATLAB—COMSOL 对照

这里比较相同的 10×10 面内网格、十个物理层、U 分布、材料、边界和观测量。COMSOL 使用二次三维实体，MATLAB 使用 LRT5 五自由度壳，所以这是独立非同构交叉验证，不是机器精度同构验证。

| 目标/mm | MATLAB/V | COMSOL/V | 电势差/% | MATLAB/A | COMSOL/A | 磁势差/% |
|---:|---:|---:|---:|---:|---:|---:|
| 0.5 | 78.431689371 | 79.874160188 | 1.839143 | 0.0308809096 | 0.0314488536 | 1.839143 |
| 1.0 | 156.863378742 | 159.748320376 | 1.839143 | 0.0617618191 | 0.0628977072 | 1.839143 |
| 2.0 | 313.726757484 | 319.496640751 | 1.839143 | 0.1235236383 | 0.1257954144 | 1.839143 |

两软件的 \(|\Delta\phi/\Delta\psi|\) 均为约 2539.811504，比例差不超过 \(7.2\times10^{-13}\%\)。这支持材料常数、符号和通道尺度一致；电、磁误差相同是同一线性本构比例的结果，不能当作两个统计独立证据。1.839% 剩余差异符合三维实体与壳运动学的模型形式差异，并低于本交叉验证 5% 门槛。

正式证据文件：

- `outputs/code_closure/comsol_four_field/comsol_four_field_summary.csv`
- `outputs/code_closure/comsol_four_field/comsol_four_field_layers.csv`
- `outputs/code_closure/comsol_four_field/comsol_four_field_physics_manifest.csv`
- `outputs/code_closure/comsol_four_field/comsol_four_field_channel_isolation.csv`
- `outputs/code_closure/comsol_four_field/comsol_four_field_Model.mph`

## 第 6 步：仅代码闭环交付包与全链路验收

状态：`PASS_FULL_CODE_CLOSURE`。

交付路径：

- 目录：`outputs/fgmee_final_delivery_20260720`
- 压缩包：`outputs/fgmee_final_delivery_20260720.zip`

本步先运行 builder 和 `RUN_CHECK`，再从包内分别调用 COMSOL 编译入口与 MATLAB inverse 重算入口。实际运行发现并修复了两个只靠静态门禁无法发现的交付缺口：

1. 包内 `RUN_COMSOL.ps1` 原先没有设置正式 Java 所要求的 `FG_FOUR_FIELD_RUN_ID` 和 `FG_FOUR_FIELD_SOURCE_SHA256`；现在运行前生成 UTC 标识并计算被编译源码的 SHA-256。
2. builder 原先漏复制 `build_active_layer_dof_map.m` 和 `interpolate_shell_dof_at_point.m`；包内 MATLAB 第一次实跑在 10×10 起点报缺函数。现在两文件既被直接复制，也被列入 `RUN_CHECK` 必需文件，并增加了失败先行的回归测试。

最终验收结果：

| 验收项 | 实际结果 |
|---|---|
| MATLAB 单元/结构测试 | 10/10 通过 |
| Python 正负门禁测试 | 33/33 通过 |
| COMSOL 源码/正式证据契约 | 2/2 通过 |
| PowerShell AST | 3/3 通过 |
| 包内 COMSOL inverse 编译 | `Compiled RunBlockTriangularInverseSensorCfffValidation successfully.` |
| 包内 MATLAB inverse 重算 | 10/15/20/30 全部完成，耗时约 602 s |
| 包内 MATLAB 重算 CSV | 12 行；4 网格、3 目标、4 个案例哈希；全部 `layer_local_pyro_v3`/`ok` |
| 包内重算与正式 MATLAB 数值 | 电势、磁势及两类残差逐行一致，0 项差异 |
| `RUN_CHECK.ps1` | `PASS_FULL_CODE_CLOSURE`，14 项检查、0 项失败 |
| 包内容 | 84 个载荷文件；75 个直接复制来源哈希通过 |

正式包明确排除了旧 20260715 TEX/PDF、旧报告图、宏和 `BUILD_REPORT.ps1`。`metadata/MANIFEST.csv`、`metadata/SHA256SUMS.txt` 与 `metadata/SOURCE_PROVENANCE.csv` 分别约束文件白名单、包内哈希和“工作区源码 → 包内源码”同一性。

## 当前结论边界

- 已修复并验证的是本项目代码；钱沈云代码未被改写。
- 已证明逐层组装、映射/凝聚、中心探针、各向异性项、MATLAB 网格链和 COMSOL 独立四场链在各自门禁内成立。
- 尚不能把钱沈云论文整体判为错误，也不能把非同构模型的 1.839% 差异写成同构精度。
- MATLAB 每档网格的三个位移结果来自线性缩放；COMSOL 三个位移为三次独立 Stationary 重求。
- MATLAB 30×30 机械—热矩阵病态，小残差不构成高前向精度保证。
